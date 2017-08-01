class ProductsImage < ActiveRecord::Base
	has_one  :user, :foreign_key => :id, :primary_key => :user_id

	has_attached_file :image,
		:styles => {
			:original => {geometry: "1024x768>", format: :jpg, paperclip_optimizer: {jpegoptim: {strip: :all, max_quality: 75}}},
			:medium => {geometry: "388x291>", format: :jpg, paperclip_optimizer: {jpegoptim: {strip: :all, max_quality: 70}}},
			:thumb => {geometry: "200x150>", format: :png, paperclip_optimizer: {advpng: {level: 4}} },
		},
		:processors => [:thumbnail, :paperclip_optimizer], #:own_watermark
		:default_url => "/assets/images/no_image.png",
		:url => "/uploads/products/:style/:hash.:extension",
		:path => ":rails_root/public/uploads/products/:style/:hash.:extension",
		:hash_secret => "super_git_passcode",
		:hash_data => ":class/:attachment/:id/:style/:created_at", # default: ":class/:attachment/:id/:style/:updated_at"
		:preserve_files => false
		# :only_process => [:small]
	
	# delayed_paperclip
	# process_in_background :avatar, only_process: [:small] # or only_process: lambda { |a| a.instance.small_supported? ? [:small, :large] : [:large] }
	
	validates_attachment :image, :content_type => { :content_type => ["image/jpeg", "image/pjpeg", "image/png", "image/x-png"] }, :size => { :in => 0..PRODUCT_IMAGE_UPLOAD_MAX_FILE_SIZE }
	validates_attachment_file_name :image, :matches => [/png\Z/, /jpe?g\Z/, /jpg\Z/]
	#validates_attachment_presence :image
	
	before_post_process :check_file_size
	#before_post_process :randomize_filename
	
  
	def to_jq_fileupload (original_filename)
		return {
		"name" => ((original_filename.present?) ? original_filename : read_attribute(:image_file_name)),
		"size" => image.size,
		"url" => image.url(:original),
		"thumbnail_url" => image.url(:thumb),
		"id" => self.id,
		}
	end
	
	
	def zoom_style
		if(self.thumb_zoom.present? && (self.thumb_zoom >= 10))
			self.thumb_zoom = 100 if(self.thumb_zoom > 100)
			tzhalf = (self.thumb_zoom / 2).to_i.to_s
			tzquart = (self.thumb_zoom / 4).to_i.to_s
			tzoom = (self.thumb_zoom + 100).to_s
			return ('max-width: ' + tzoom + '%; max-height: ' + tzoom + '%; margin-left: -' + tzhalf + '%; margin-top: -' + tzquart + '%;')
		end
		return nil
	end

	
	private
	
	
	def check_file_size
		valid?
		errors[:image_file_size].blank?
	end
  
end
