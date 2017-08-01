# Paperclip does not use hashing when generating attachment paths, by default:

#Paperclip::Attachment.default_options.update({
#  url: "/system/:class/:attachment/:id_partition/:style/:hash.:extension",
#  hash_secret: Rails.application.secrets.secret_key_base,
#  #hash_data: ":class/:attachment/:id/:style/:updated_at",
#  #hash_digest: "SHA1",
#})