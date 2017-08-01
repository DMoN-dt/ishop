
window['on_cart_change'] = (ret,panel_id,form_id,b_delayed,query,ret_success,data,jqxhr) ->
  if(ret_success != null) && (typeof ret_success['result'] != "undefined")
    if((typeof ret_success['result']['guest_limit_exceeded'] != "undefined") && (ret_success['result']['guest_limit_exceeded'] == true))
      text = '<p>В корзине находится ' + ret_success['result']['cnt'] + ' наименований товаров.</p><p>У нас действует ограничение для незарегистрированных посетителей.</p><p><b>Продолжить добавление товаров в корзину можно только после входа или регистрации.</b></p>'
      window['show_modal']('Корзина', text , null, '<button type="button" class="btn btn-secondary" data-dismiss="modal">Закрыть</button><a href="/users/login/" class="button btn btn-primary">Войти</a>')
    else if((typeof ret_success['result']['user_limit_exceeded'] != "undefined") && (ret_success['result']['user_limit_exceeded'] == true))
      text = '<p>У нас действует ограничение на максимальное количество товаров в корзине пользователя.</p><p><b>В корзине превышен максимальный предел 30 товаров.</b></p>'
      window['show_modal']('Корзина', text , null, '<button type="button" class="btn btn-secondary" data-dismiss="modal">Закрыть</button><a href="/cart/show/" class="button btn btn-primary">Перейти в корзину</a>')
    else
      if(ret_success['result']['cnt'] > 0)
        text = ret_success['result']['cnt']
        $(".cart-count").show()
        window['btn_add_to_cart_quantity'](panel_id,ret_success,true)
      else
        text = ''
        $(".cart-count").hide()
      $(".cart-count").text(text)


window['btn_add_to_cart_quantity'] = (panel_id,ret_success,force_btn_change) ->
  if((typeof ret_success['result']['pid_cnt'] != "undefined") && (ret_success['result']['pid_cnt'] != null))
    ncnt = parseInt(ret_success['result']['pid_cnt'])
    if(ncnt == 0)
      cnt = ''
      btn_change = false
    else
      if(ncnt != 1)
        cnt = ' (' + ncnt + ')'
      else
        cnt = ''
      btn_change = true
  else
    cnt = ''
    btn_change = false
  
  if(btn_change or force_btn_change)
    ptr = $('#' + panel_id + ' button.add-to-cart:first')
    if(ptr.length == 1)
      ptr.addClass("exist-in-cart")
      ptr.removeClass("add-to-cart")
    else
      ptr = $('#' + panel_id + ' button.exist-in-cart:first')
    if(ptr.length == 1)
      ptr.find(".label").text("В корзине" + cnt)


window['on_cart_update_list'] = () ->
  n = 1


window['on_cart_show'] = () ->
  $cartd = $("#cart_data")
  
  if(window['isMobile']())
    fade_eff = ''
  else
    fade_eff = 'fade'
    
  rnd = Math.floor(Math.random() * 10)
  
  title = 'Моя Корзина'
  text = '<div id="cart_body"></div>'
  button_type = null
  buttons = '<button type="button" class="btn btn-secondary" data-dismiss="modal">Закрыть</button><a href="/orders/start/" class="button btn btn-primary btn-order">Оформить заказ</a>'
  ptr = $(".cart-count:first")
  if(ptr.length == 1)
    if(ptr.text() == "0")
      buttons = '<button type="button" class="btn btn-primary" data-dismiss="modal">Закрыть</button>'
  
  d_dialog_id = "modal_cart" + rnd + "_" + Date.now()
  modal_html = '<div class="modal ' + fade_eff + '" id="' + d_dialog_id + '" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true"><div class="modal-dialog" role="document"><div class="modal-content"><div class="modal-header"><h5 class="modal-title" id="exampleModalLabel">' + title + '</h5><button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button></div><div class="modal-body">' + text + '</div><div class="modal-footer">' + buttons + '</div></div></div></div>'
  $("#idbody").append(modal_html)
  dialog_id = '#' + d_dialog_id
  $(dialog_id + ' #cart_body').append($cartd)
  
  $(dialog_id).on('hidden.bs.modal', ->
    $cartd.detach()
    $("#hidden_body").append($cartd)
    $(dialog_id).remove()
  )
  $(dialog_id).modal()

  sq_params = {'frame_id': d_dialog_id + ' .modal-body #cart_body #cart_data', 'wait_block': d_dialog_id + ' .modal-body #cart_body', 'handler_func': window['on_cart_update_list'], 'no_status_ok': true}
  window['OnFlyEG_QueryUrl'](d_dialog_id, '/cart/show/', 'get', 'html', {}, sq_params)
  
  
window['on_cart_disable_guest'] = (this_obj, panel_id) ->
  panel = $(panel_id + ":first")
  if(panel.length == 1)
    if($(this_obj).is(":checked"))
      panel.find(".product[data-mark='guest']").addClass('disabled')
      panel.attr('list-summ', panel.find(".total .price-summ .value").text())
      price = panel.attr('price-user')
      if((typeof price == "undefined") || (price == null))
        price = user_price
      panel.find(".total .price-summ .value").text(price)
      panel.find("input#noguest").val(1)
    else
      panel.find(".product[data-mark='guest']").removeClass('disabled')
      panel.find(".total .price-summ .value").text(panel.attr('list-summ'))
      panel.find("input#noguest").val(0)


window['change_quantity_show'] = (this_obj) ->
  othis = $(this_obj)
  qnt_form = $("#edit_quantity:first")
  if(qnt_form.length == 1)
    qnt_input = $("input.quantity-input:first", qnt_form)
    coord = othis.offset()
    pcoord = $(".cart-list").offset()
    qnt_form.show()
    fcoord = qnt_form.offset()
    icoord = qnt_input.offset()
    dtx = icoord.left - fcoord.left
    dty = icoord.top  - fcoord.top
    qnt_form.css('top', coord.top - pcoord.top - dty)
    qnt_form.css('left', coord.left - pcoord.left - dtx)
    qnt_input.val(othis.val())
    $(".unit-quantity:first", qnt_form).text(othis.siblings(".unit-quantity").text())
    qnt_input.focus()
    $("input#qnt_item_id", qnt_form).val(othis.parents(".product:first").attr("data-product-uid"))

window['change_quantity_hide'] = (this_obj) ->
  othis = $(this_obj)
  qnt_form = othis.parents("#edit_quantity:first")
  if(qnt_form.length == 1)
    qnt_form.hide()
    $("input#qnt_item_id", qnt_form).val("")


window['on_plus_minus_click'] = (event, this_obj) ->
  event.preventDefault()
  othis = $(this_obj)
  oparent = othis.parents("div:first")
  fval = $("[plusmn_val]:first", oparent)
  if(fval.length == 1)
    ftag = fval[0].nodeName
    if(ftag == "INPUT")
      cval = fval.val()
    else
      cval = fval.text()
    if($.isNumeric(cval))
      cval = parseInt(cval)
      if(cval < 0)
        cval = 0
      else
        if(othis.attr('plusmn') == 'plus')
          cval = cval + 1
        else
          if(cval > 0)
            cval = cval - 1
          else
            cval = 0
      if((cval == 0) && (fval.attr('plusmn_nonzero')=="true"))
        cval = 1
      if(ftag == "INPUT")
        fval.val(cval)
      else
        fval.text(cval)
  return false


window['on_remove_link_click'] = (this_obj, parent_id) ->
  pmain = $(this_obj).parents("div[item-delete-avail='true']:first")
  if(pmain.length == 1)
    id = pmain.attr('data-product-uid')
    if((typeof id != "undefined") && (id != undefined))
      sq_params = {'wait_block': pmain.attr('id'), 'handler_func': window['on_remove_link'], 'no_status_ok': true, 'cart_cnt_update': true}
      window['OnFlyEG_QueryUrl'](parent_id, '/cart/delete_item.json', 'post', 'json', {'id': id}, sq_params)


window['on_remove_link'] = (ret,panel_id,form_id,b_delayed,query,ret_success,data,jqxhr) ->
  if(ret_success != null) && (typeof ret_success['result'] != "undefined")
    if((typeof ret_success['result']['noaction'] == "undefined") || (ret_success['result']['noaction'] != true))
      panel = $('#' + panel_id + ":first")
      ptr = panel.find('#' + query['wait_block'] + ':first')
      if(ptr.length == 1)
        panel_list = ptr.parents('div.list:first')
        ptr.remove()
        set_footer()
        if((panel_list.length == 1) && (panel_list.children('div').length == 0))
          list_empty = true
          panel_list.html('<p>Список пуст.</p>')
          panel_list.css('overflow', 'hidden')
        else
          list_empty = false
        if((typeof query['cart_cnt_update'] != "undefined") && (query['cart_cnt_update'] == true))
          new_price = false
          if((typeof ret_success['result']['price_total'] != "undefined") && (ret_success['result']['price_total'] != undefined))
            price_total = ret_success['result']['price_total']
            new_price = true
          if((typeof ret_success['result']['price_user'] != "undefined") && (ret_success['result']['price_user'] != undefined))
            user_price = ret_success['result']['price_user']
            new_price = true

          if(new_price)
            if(panel.find(".total .price-summ").length == 1)
              if(list_empty)
                panel_list.html('<p>Корзина пуста.</p>')
                panel.find(".total").hide()
                panel.find("#order_form").hide()
                set_footer()
              else
                panel.attr('list-summ', price_total)
                panel.attr('price-user', user_price)
                check = panel.find(".total input[name='no_guest']")
                if((check.length == 1) && (check.is(":checked")))
                  panel.find(".total .price-summ .value").text(user_price)
                else
                  panel.find(".total .price-summ .value").text(price_total)
        
          if(ret_success['result']['cnt'] > 0)
            text = ret_success['result']['cnt']
            $(".cart-count").show()
            ptr = panel.find('button.add-to-cart:first')
            if(ptr.length == 1)
              ptr.find(".label").text("В корзине")
              ptr.addClass("exist-in-cart")
              ptr.removeClass("add-to-cart")
          else
            text = ''
            $(".cart-count").hide()
          $(".cart-count").text(text)


window['panel_check_required_fields'] = (parent_obj, important_fields, b_check_itemid = false, b_highlite = false) ->
  b_present_empty = false
  b_present_notempty = false
  
  if(important_fields != undefined && important_fields != '')
    important_fields = important_fields.split(' ')
    important_fields.forEach (ar_elem_id) ->
      a_elem=parent_obj.find("#" + ar_elem_id)
      if(a_elem.length > 0)
        if(b_check_itemid || ar_elem_id!="item_id")
          if((a_elem.val().trim() == "") || ((a_elem.prop("tagName").toUpperCase()=='SELECT') && (a_elem.val()=="0")))
            b_present_empty = true
            if(b_highlite)
              a_elem.addClass('check_empty_field')
          else
            b_present_notempty = true
            if(b_highlite)
              a_elem.removeClass('check_empty_field')
        
  parent_obj.find("input[required], select[required]").each ->
    a_elem = $(this)
    if(b_check_itemid || a_elem.attr('id')!="item_id")
      if((a_elem.val().trim() == "") || ((a_elem.prop("tagName").toUpperCase()=='SELECT') && (a_elem.val()=="0")))
        b_present_empty = true
        if(b_highlite)
          a_elem.addClass('check_empty_field')
      else
        b_present_notempty = true
        if(b_highlite)
          a_elem.removeClass('check_empty_field')
  if(b_highlite)
    $status_container=$('.status_block:first', parent_obj)
    if(b_present_empty)
      $status_container.html('Некоторые обязательные поля не заполнены!')
      window['status_block_set_state']($status_container, 'error')
      $status_container.show('fast')
    else
      $status_container.html('')
      $status_container.hide()
  return ['empty': b_present_empty, 'not_empty': b_present_notempty]


window['form_onsubmit_validate'] = (_form) ->
  ret = window['panel_check_required_fields'](_form, _form.attr("important-fields"), false, true)
  if(ret[0]['empty'] == true)
    return false
  $('.check_empty_field', _form).removeClass('check_empty_field')
  return true


window['form_onsubmit'] = (event, data) ->
  etarget = $(event.target)
  if(etarget.is("form.secured_form"))
    gcap = etarget.find("[name='g-recaptcha-response']:first")
    if((gcap.length == 0) || (gcap.val() == ""))
      event.preventDefault()
      if(window['form_onsubmit_validate'](etarget))
        cid = $(etarget).attr('data-recaptcha-id')
        if((typeof cid != "undefined") && (cid != ""))
          grecaptcha.execute(cid)
  
      else
        wait_block = etarget.parents("div[data-form-wait]:first")
        if((wait_block.length == 0) || (wait_block.find("form").length > 1))
          wait_block = etarget
        $("<div class='wait_ajax on-block'></div>").appendTo(wait_block)
        $(".wait_ajax", wait_block).show()
  else if(etarget.is("form"))
    if(!window['form_onsubmit_validate'](etarget))
      etarget.on('change', (e, data) -> 
        etarget.find('input[type="submit"]:first, button[type="submit"]:first, .btn-submit:first').removeAttr('disabled')
      )
      return false


window['isMobile'] = () ->
  if((typeof window['isMobile_var'] != "undefined") && (window['isMobile_var'] != undefined))
    return window['isMobile_var']
  mobiles = ['Android', 'BlackBerry', 'iPhone', 'iPad', 'iPod', 'Opera Mini', 'IEMobile', 'Silk']
  ua = navigator.userAgent || navigator.vendor || window.opera

  for i in [0,mobiles.length-1]
    if(ua.toString().toLowerCase().indexOf(mobiles[i].toLowerCase()) > 0)
      window['isMobile_var'] =  mobiles[i]
      return mobiles[i]
  window['isMobile_var'] = false
  return false
  

window['global_onclick'] = (event) ->
  etarget = $(event.target)
  if(etarget.is("a[data-with-ajax]"))
    if(event.target.tagName == 'A')
      method = 'get'
      type = 'json'
      url = event.target.href
    adata = event.target.getAttribute("data-with-ajax")
    if(typeof adata != "undefined")
      adata = adata.split("/")
      method = adata[0]
      if(typeof adata[1] != "undefined")
        type = adata[1]
    adata = event.target.getAttribute("data-method")
    if(typeof adata != "undefined") && (adata != null)
      method = adata

    if(typeof method != "undefined") && (typeof type != "undefined") && (typeof url != "undefined")
      event.preventDefault()
      sq_params = {'frame_id': null, 'wait_block': null, 'no_status_ok': false}
      window['OnFlyEG_QueryUrl']("idbody", url, method, type, null, sq_params)
      
  else if(etarget.is("div[data-click='show-cart'], a[data-click='show-cart'], div[data-click='show-cart'] .cart-count"))
    event.preventDefault()
    location.href="/cart/show"
#    window['on_cart_show']()
  else if(etarget.is(".modal-dialog button[data-func-onclick]"))
    func_call = etarget.attr('data-func-onclick')
    if(typeof func_call != "undefined") && (func_call != null)
      eval(func_call)
    

window["global_onload"] = () ->
  $(document).on("click", window['global_onclick'])
  $(document).on("submit", window['form_onsubmit'])

window["global_teardown"] = () ->
  $(document).off("click", window['global_onclick'])
  $(document).off("submit", window['form_onsubmit'])

$(document).on("ready turbolinks:load", window["global_onload"])
$(document).on("turbolinks:before-cache", window["global_teardown"])