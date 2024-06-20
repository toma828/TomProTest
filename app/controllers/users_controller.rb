class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]

  # GET /users or /users.json
  def index
    @users = User.all
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)
  
    respond_to do |format|
      if @user.save
        if process_video(@user, @user.avatar.path) # @user を引数に渡す
          format.html { redirect_to @user, notice: 'User was successfully created.' }
          format.json { render :show, status: :created, location: @user }
        else
          format.html { render :new, alert: 'Video processing failed.' }
          format.json { render json: { error: 'Video processing failed.' }, status: :unprocessable_entity }
        end
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        if process_video(@user.avatar.path)
          format.html { redirect_to @user, notice: 'User was successfully updated.' }
          format.json { render :show, status: :ok, location: @user }
        else
          format.html { render :edit, alert: 'Video processing failed.' }
          format.json { render json: { error: 'Video processing failed.' }, status: :unprocessable_entity }
        end
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_url, notice: "User was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def process_video(user, video_path)
    output_path_mp4 = "#{File.dirname(video_path)}/bw_#{File.basename(video_path, '.*')}.mp4"
    output_path_gif = "#{File.dirname(video_path)}/bw_#{File.basename(video_path, '.*')}.gif"
    Rails.logger.info "Running python script to convert video to black and white"
    result = system("python3 Python/convert_to_black_and_white.py #{video_path} #{output_path_mp4} #{output_path_gif}")
    Rails.logger.info "Python script executed: #{result}"
    if File.exist?(output_path_gif)
      user.update(avatar: File.open(output_path_gif)) # user を使って更新
      Rails.logger.info "Video processed and file saved: #{output_path_gif}"
      return true
    else
      Rails.logger.error "Video processing failed. File not found: #{output_path_gif}"
      return false
    end
  end

  def set_user
    @user = User.find(params[:id])
  end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:username, :age, :avatar)
    end
end
