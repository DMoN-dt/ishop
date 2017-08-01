Rails.application.routes.draw do

  root 'welcome#index'
  
  # scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/, defaults: {locale: "en"} do ... end
  
  resources :cabinet do
	collection do
		get   'orders'
		get   'orders/:list_type', action: 'orders'
		get   'discounts'
		get   'cart', action: 'show', controller: 'carts'
		get   'e-commerce'
		
		if(defined?(MARKETPLACE_MODE_ONLINE_SHOP) && (MARKETPLACE_MODE_ONLINE_SHOP != true))
			get   'sellers'
		end
	end
  end

  resources :user, except: [:update, :edit] do
	collection do
		get   'profile'
		match 'profile_edit', via: [:get, :post]
		match 'profile_fill', via: [:get, :post]
		get   'wait_confirm'
		get   'payments/:list', action: 'payments'
		get   'payments', action: 'payments'
	end
  end
  
  resources :orders do
	collection do
		get   'begin', controller: 'carts', action: 'show', change_qnt: false
		get   'express', controller: 'carts', action: 'show', change_qnt: false
		
		get   'start', action: 'begin'
		post  'begin', action: 'begin'
		post  'express'
		match 'new', action: 'new', via: [:get, :post]
		match 'pay', action: 'pay', via: [:get, :post], controller: 'payments'
		get   'show/:order_uid', action: 'show', item_uid: nil
		post  'delete'
		match 'cancel', via: [:get, :post]
		post  'cancel.json', action: 'cancel'
		
		scope :change, :as => 'change' do
			post  'delivery_charges.json', action: 'change_delivery_charges'
			post  'agree.json', action: 'change_agree'
			post  'accept.json', action: 'change_accept'
			post  'delete_item.json', action: 'change_delete_item'
			get   'delete_item', action: 'change_delete_item'
		end
	end
  end
  
  resources :products do
	collection do
		get   'import'
		get   'import_groups', action: 'import', constraints: { format: 'html' }
		get   'import_products', action: 'import', constraints: { format: 'html' }
		get   'import_products_save', action: 'import', constraint: { format: 'html' }
		
		post  'import', action: 'import_price'
		post  'import_groups', action: 'import_price_groups_save'
		post  'import_products', action: 'import_price_products'
		post  'import_products_save', action: 'import_price_products_save'
		
		scope :update, :as => 'update' do
			get   'with_suppliers', action: 'update_with_suppliers'
			get   'with_suppliers_save', action: 'update_with_suppliers'
			post  'with_suppliers_save', action: 'update_with_suppliers_save'
		end
		
		post  'images_edit', action: 'images_edit'
		post  'images_add.json', action: 'images_add', constraints: { format: 'json' }
		post  'images_delete.json', action: 'images_delete', constraints: { format: 'json' }
	end
  end
  
  get   '/product/:pub_id', controller: 'products', action: 'show'
  get   '/product/archive/order/:order_safe_uid.:order_safe_uid_part/:pub_id', controller: 'products', action: 'show_archived'
  
  resources :payments do
	collection do
		match 'pay', action: 'pay', via: [:get, :post]
		
	end
  end
  
  resources :customers, except: [:destroy] do
	collection do
		match ':id/delete(.:format)', action: 'destroy', via: [:get, :post]
	end
  end
  
  resources :destinations, except: [:show, :destroy] do
	collection do
		match ':id/delete(.:format)', action: 'destroy', via: [:get, :post]
	end
  end
  
  get   '/payment/check_order/', controller: 'payments', action: 'check_order', production_mode: true
  post  '/payment/check_order/', controller: 'payments', action: 'check_order', production_mode: true
  post  '/payment/success/', controller: 'payments', action: 'success', production_mode: true
  get   '/payment/onsucceed/', controller: 'payments', action: 'onsucceed', production_mode: true
  get   '/payment/onfailure/', controller: 'payments', action: 'onfailure', production_mode: true
  get   '/payment/test/check_order/', controller: 'payments', action: 'check_order', production_mode: false
  post  '/payment/test/check_order/', controller: 'payments', action: 'check_order', production_mode: false
  post  '/payment/test/success/', controller: 'payments', action: 'success', production_mode: false
  get   '/payment/test/onsucceed/', controller: 'payments', action: 'onsucceed', production_mode: false
  get   '/payment/test/onfailure/', controller: 'payments', action: 'onfailure', production_mode: false
  
  get   '/catalog/:cat_group_id/f/:brand_name/:model_name/:model_year_num', controller: 'products', action: 'show_list'
  get   '/catalog/:cat_group_id/f/:brand_name/:model_name', controller: 'products', action: 'show_list'
  get   '/catalog/:cat_group_id/f/:brand_name', controller: 'products', action: 'show_list'
  get   '/catalog/:cat_group_id', controller: 'products', action: 'show_list'
  get   '/catalog/', controller: 'products', action: 'show_list'
  
  get   '/cart/show', controller: 'carts', action: 'show', change_qnt: false
  post  '/cart/show', controller: 'carts', action: 'show', change_qnt: true
  post  '/cart/change_item.json', controller: 'carts', action: 'change_item'
  post  '/cart/delete_item.json', controller: 'carts', action: 'delete_item'
  post  '/cart/is_in_cart.json', controller: 'carts', action: 'is_in_cart'
  
  resources :pay_invoices do
	collection do
		get  'show', action: 'show', print_ver: false
		get  'print', action: 'show', print_ver: true
		get  'print.pdf', action: 'show', print_ver: true, constraints: { format: 'pdf' }
	end
  end
  
  resources :search, only: [:index] do
	collection do
		post '', action: 'index'
	end
  end
  
  post  '/auto/:brand_name.json', controller: 'gen_brands', action: 'get_submodels'
  post  '/auto/:brand_name/:model_name.json', controller: 'gen_brands', action: 'get_submodel_years'
  get   '/auto/:brand_name', controller: 'products', action: 'show_list'
  #get   '/auto/:brand_name/:model', controller: 'products', action: 'show_list', list_filter: :model
  
  get   '/faq/:text_id', controller: 'content_pages', action: 'show'
  get   '/contacts/', controller: 'content_pages', action: 'show', text_id: 'contacts'
  get   '/privacy/', controller: 'content_pages', action: 'show', text_id: 'privacy_policy'
  get   '/for-buyers/', controller: 'content_pages', action: 'show', text_id: 'terms_sale'

  ## USERS LOGON
  devise_for :users, path_names: { sign_in: 'login', sign_out: 'logout' }, :controllers => { sessions: "user/sessions", passwords: "user/passwords", registrations: "user/registrations" } #, skip: [:registrations]#, :controllers => { omniauth_callbacks: 'omniauth_callbacks' } #, :controllers => { sessions: "users/track_sessions" }
  
  ## ERRORS
  get   'error/403' => 'welcome#error_403'
  get   'error/404' => 'welcome#error_404'
  get   'error/denied', controller: 'welcome', action: 'error_access_denied'
  
  ## SPAM-VIRUS ROBOTS
  match 'admin' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'admin:smth' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'admin:smth/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'wp-login.php' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'webdav' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'myadmin/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'MyAdmin/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'mysqladmin/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'mysql/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'websql/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'dbadmin/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'db/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'phpmyadmin/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'phpmyadmin:smth/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'phpMyAdmin/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'phpMyAdmin:smth/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'php-my-admin/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'pma/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'scripts/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'bitrix/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'typo3/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'fck/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'xampp/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'muieblackcat' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'web/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'HNAP1' => 'welcome#error_RobotTryLogin', via: [:get, :post] # Routers Home Network Administration Protocol
  match 'modules/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'wp-content:smth' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'cgi-bin/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'moadmin/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'catalog/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match 'shop/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post]
  match '/CFIDE/*other' => 'welcome#error_RobotTryLogin', via: [:get, :post] # ColdFusion

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
