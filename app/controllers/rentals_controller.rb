class RentalsController < ApplicationController
  # load_and_authorize_resource
  before_action :authenticate_user!
  before_action :set_rental, only: [:show, :edit, :update, :destroy]

  def index
    @rentals = Rental.where.not(:status => 'progress')
  end

  def show
  end

  def new
    @rental = current_rental
    @rental_details = @rental.rental_details
  end

  def create
    @rental = Rental.new(rental_params)
    @rental.status = "application"
    @rental.User = current_user
    if @rental.save
      redirect_to rentals_path
    else
      render 'new'
    end
  end

  def edit
    if @rental.blank?
      @rental = current_rental
    end
    @@status = @rental.status
    @can_update = islabaware_detail_change(@rental)
    @rental_details = @rental.rental_details
    logger.debug @rental
  end

  def update
    if @rental.User.blank?
      @rental.User = current_user
      @rental.status = "application"
    end
    logger.debug @@status + " HHH"
    if @rental.update(rental_params)
      if can? :change_status, Rental then
        if @rental.status.eql?("approval") and (@@status.eql?("application") or @@status.eql?("reject")) then
          @rental.rental_details.each do |i|
            labwares = Labware.where("name = ?",i.labware.name)
            labwares.each do |labware|
              labware.circulation += i.quantity
              labware.update(labware_params)
            end
          end
        elsif @rental.status.eql?("reject") and @@status.eql?("approval") then
          @rental.rental_details.each do |i|
            labwares = Labware.where("name = ?",i.labware.name)
            labwares.each do |labware|
              labware.circulation -= i.quantity
              labware.update(labware_params)
            end
          end
        end
      end
      redirect_to rentals_path
      session[:rental_id] = nil
    else
      render 'edit'
    end
  end

  def destroy
      @rental.destroy
      redirect_to rentals_path
  end

private
    def rental_params
      params[:rental].permit(:rental_date, :due_date, :User_id, :status, :rack_no,rental_details_attributes: [:id, :quantity, :rental_id, :labware_id, :_destroy, labwares_attributes:[:name]])
    end
    
    def labware_params
      params.permit(:circulation)
    end

    def set_rental
      @rental = Rental.find(params[:id])
    end
    
    def islabaware_detail_change(rental)
      bret = true
      if rental.User.eql?(current_user)
        if rental.status.eql?('application')  then
          bret = false
        end
      elsif rental.User.blank? 
        bret = false
      end
      
      return bret
    end
end
