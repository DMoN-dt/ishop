class PayInvoicePartner < PayInvoice
	
	#Verify the access after Main Rights verification
	def object_has_access? (rights, pAccessList = @rAcl)
		
	end
end
