require 'marketplace'

class String
	def numeric?
		Float(self) != nil rescue false
	end
	
	def sanitize(options={})
		ActionController::Base.helpers.sanitize(self, options)
	end
	
	def escape_html
		CGI::escape_html(self)
	end
	
	def titleize_unicode
		space = self.index(' ')
		return UnicodeUtils.titlecase(self) if(space.nil?)
		str = self[0..space]
		return UnicodeUtils.titlecase(str) + self[space, self.length]
	end
	
	def delimiter_thousands (separator = ' ')
		ln = self.length
		cs = ln / 3
		cs -= 1 if((ln % 3) == 0)
		nn = ln + cs
		str = ' ' * nn
		ln -= 1
		nn -= 1
		a = 0
		while ln >= 0 do
			if(a >= 3)
				a = 0
				str[nn] = separator
				nn -= 1
				break if(nn < 0)
			end
			str[nn] = self[ln]
			ln -= 1
			nn -= 1
			a += 1
		end
		return str
	end
end


#if(defined? Fixnum)
#	class Fixnum
#		def numeric?
#			return true
#		end
#	end
#end


# Исправление косяка в Ruby - если какой-то файл не в кодировке utf-8 содержит текст utf-8, то ruby грохается без указания файла с ошибкой.
module ActionDispatch
	class ExceptionWrapper
		def ensure_utf8 (string)
			content = ""
			string.each_char do |char|
				enc_char = char.force_encoding('utf-8')
				if enc_char.valid_encoding?
					content << enc_char
				else
					content << "?"
				end
			end
			content
		end
		
		def expand_backtrace
			@exception.backtrace.unshift(
				ensure_utf8(@exception.to_s).split("\n")
			).flatten!
		end
	end
end
