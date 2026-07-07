class UploadsController < ApplicationController
  def create
    blob = ActiveStorage::Blob.create_and_upload!(
      io: params[:file],
      filename: params[:file].original_filename,
      content_type: params[:file].content_type
    )

    render json: {
      url: rails_blob_url(blob, disposition: "inline"),
      filename: blob.filename.to_s
    }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
