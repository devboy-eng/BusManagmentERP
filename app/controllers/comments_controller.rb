class CommentsController < ApplicationController
  skip_before_action :authorize_feature!

  def create
    if params[:customer_id]
      @commentable = Customer.find(params[:customer_id])
      redirect_path = customer_path(@commentable)
    elsif params[:lead_id]
      @commentable = Lead.find(params[:lead_id])
      redirect_path = lead_path(@commentable)
    end

    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to redirect_path, notice: "Comment added successfully."
    else
      redirect_to redirect_path, alert: "Comment cannot be blank."
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
end
