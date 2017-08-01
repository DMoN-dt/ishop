class Vendor < ActiveRecord::Base
	has_one  :user, :foreign_key => :id, :primary_key => :user_id
	
	has_attached_file :logo,
		:styles => {
			:original => {geometry: "209x60>", format: :png, paperclip_optimizer: {advpng: {level: 4}} },
		},
		:processors => [:thumbnail, :paperclip_optimizer],
		:default_url => "",
		:url => "/vendor_logos/:basename.:extension",
		:path => ":rails_root/public/vendor_logos/:filename",
		:preserve_files => false

	validates_attachment :logo, :content_type => { :content_type => ["image/jpeg", "image/pjpeg", "image/png", "image/x-png"] }, :size => { :in => 0..250.kilobytes }
	validates_attachment_file_name :logo, :matches => [/png\Z/, /jpe?g\Z/, /jpg\Z/]
	
	before_post_process :check_file_size

	
	def logo_url
		return self.logo.url(:original)
	end
	
	
	private
	
	
	def check_file_size
		valid?
		errors[:image_file_size].blank?
	end

end
