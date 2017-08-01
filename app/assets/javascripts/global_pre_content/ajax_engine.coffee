# === AJAX ON-THE-FLY ENGINE FUNCTIONS ===

window['OnFlyEG_QueryParamsList'] = ['handler_func', 'wait_block', 'wait_container', 'status_container', 'no_status_ok', 'query_uid', 'form_id', 'frame_id', 'pframe', 'waitfor_status', 'waitfor_cmd', 'waitfor_templateid', 'waitfor_funccall']


window['OnFlyEG_FindQuery'] = (panel_id, url, status_search, status_new, sq_params, b_reject_from_queue) ->
  if((typeof window['var_global_ajax_queue'] == "undefined") || (window['var_global_ajax_queue'] == undefined))
    return null
  n=window['var_global_ajax_queue'].length
  if(n>1000)
    n=1000
  for i in [0..n]
    if(typeof window['var_global_ajax_queue'][i] == "undefined")
      continue
    _waitfor = window['var_global_ajax_queue'][i]
    if(_waitfor['panel_id'] == panel_id) && (_waitfor['frame_id']==sq_params['frame_id']) && (((sq_params['form_id'] != null) && (_waitfor['form_id']==sq_params['form_id'])) || ((sq_params['form_id'] == null) && (_waitfor['query_uid']==sq_params['query_uid']))) && (_waitfor['form_url']==url)
      if(_waitfor['status'] == status_search)
        return _waitfor
  return null


window['OnFlyEG_StoreQuery'] = (stage, url, panel_id, sq_params) ->
  if(typeof window['var_global_ajax_queue'] == "undefined")
    window['var_global_ajax_queue'] = new Array()
  window['OnFlyEG_QueryParamsList'].forEach (sqp_name) ->
    if(typeof sq_params[sqp_name] == "undefined")
      sq_params[sqp_name] = null

  if(stage=='in_queue')
    wid = window['var_global_ajax_queue'].length
    window['var_global_ajax_queue'][wid] = {'status': 'in_queue', 'panel_id': panel_id, 'form_url': url}
    $.extend(window['var_global_ajax_queue'][wid], sq_params)
    
    if(sq_params['wait_block'] != null)
      wait_block = $('#' + sq_params['wait_block'] + ":first", $('#' + panel_id))
    $(document).ajaxSend (event, jqxhr, settings) ->
      window['OnFlyEG_StoreQuery']('send', settings['url'], panel_id, sq_params)
    
  else if(stage=='send')
    if(window['OnFlyEG_FindQuery'](panel_id, url, 'in_queue', 'send', sq_params, false) != null)
      status_container = window['OnFlyEG_ChooseStatusBlock'](sq_params)
      status_container.html('Ожидание ответа от сервера...')
      window['status_block_set_state'](status_container, 'waitajax')
      status_container.show() if status_container.is(":hidden")

  else return


window['OnFlyEG_QueryUrl'] = (panel_id, url, url_method, ttype, params, sq_params) ->
  if(ttype=='json')
    len = url.length
    if(len > 5)
      if(url.substring(len-5,len) != '.json')
        url += '.json'
  else if(ttype!='xml')
    ttype='html'

  load_content = ((ttype == 'html') ? true : false)
  
  if((typeof sq_params == "undefined") || (sq_params == null))
    sq_params = {}
 
  sq_params["load_content"] = load_content
  sq_params["url_method"] = url_method
  sq_params["url_type"] = ttype
  
  
  params_send = {ajax: 'Y'}
  for sqp_name of sq_params
    if(sqp_name.substr(0,2) == 'd_')
      params_send[sqp_name.substr(2)] = sq_params[sqp_name]
  $.extend(params_send,params)

  if(ttype == 'html')
    if(sq_params["frame_id"] != null)
      frame_id = sq_params["frame_id"]
      frame = sq_params["pframe"]
      window['OnFlyEG_Content_UnLoad'](frame_id)
  
  $.ajax url,
    dataType: ttype
    method: url_method
    data: params_send
    beforeSend: (jqxhr, settings) ->
      query = window['OnFlyEG_FindQuery'](panel_id, url, 'in_queue', 'send', sq_params, false)
    error: (jqxhr, textStatus, errorThrown) ->
      window['OnFlyEG_OnQueryComplete'](false, panel_id, url, sq_params, null, textStatus, jqxhr, errorThrown)
    success: (data, textStatus, jqxhr) ->
      window['OnFlyEG_OnQueryComplete'](true, panel_id, url, sq_params, data, textStatus, jqxhr)


window['OnFlyEG_OnQueryComplete'] = (b_success, panel_id, url, sq_params, data, textStatus, jqxhr, exception) ->
  ret_success = null
  query = null
  call_handler_fn = true
  if(b_success)
    if(typeof jqxhr != "undefined")
      if((typeof jqxhr.responseJSON != "undefined") || (sq_params["frame_id"] != null))
        query = window['OnFlyEG_FindQuery'](panel_id, url,'send',null,sq_params,true)
      else
        stb = null
        show_ok = null

  else
    query = window['OnFlyEG_FindQuery'](panel_id, url,'in_queue',null, sq_params, true)
    window['OnFlyEG_ShowError'](event, jqxhr, null, null, null, window['OnFlyEG_ChooseStatusBlock'](query))
  
  if(query != null)
    if(call_handler_fn)
      if(query['handler_func'] != null)
        fn_handler = null
        if(typeof query['handler_func'] == "function")
          fn_handler = query['handler_func']
        else if(typeof query['handler_func'] == "string") && (query['handler_func'].substr(0,7) == "fn_wnd_")
          fname = query['handler_func'].substr(7)
          if(typeof window[fname] == "function")
            fn_handler = window[fname]
        if(fn_handler != null)
          fn_handler(ret,panel_id,null,false,query,ret_success,data,jqxhr)


window['OnFlyEG_ShowError'] = (event, jqxhr, settings, exception, errblock_parent_selector, $error_container) ->
  if($error_container == null) || (typeof $error_container == 'undefined')

  else
    $error_container_ul = $error_container
  $error_container.show() if $error_container.is(":hidden")
  window['status_block_set_state']($error_container, 'error')
  if((typeof jqxhr != "undefined")  && jqxhr != null)

  
window['OnFlyEG_ChooseStatusBlock'] = (sq_params) ->
  if(sq_params['status_container'] == null)

  else
    status_container = sq_params['status_container']
  return status_container


window['JSON_check_status'] = ($json_res, $status_container, b_show_ok, form_obj, query) ->
  ret = new Array(false,false,null,false)
  if((typeof $json_res != "undefined") && ($json_res != null) && (($json_res.constructor == Array) or ($json_res.constructor == Object)))
    if(typeof $json_res['status'] != "undefined")
      if(typeof $json_res['visit_me'] != "undefined") && (typeof query != "undefined") && (query != null)
        window['redirect_to'](query['form_url'], url_method, 'html', url_params, query)
        not_real_error=true

      else if(typeof $json_res['confirm'] != "undefined") && (typeof query != "undefined") && (query != null)

        window['show_modal'](null, confirm_text, 'confirm', null, "window[\"confirm_action\"](" + JSON.stringify(query) + ");")
        not_real_error=true
      else
        not_real_error=false
      
      if($json_res['status'] == 'error')
        if(!not_real_error)
          window['status_block_set_state']($status_container, 'error')
        
        if(typeof $json_res['bad_fields'] != "undefined")
            
          $json_res['bad_fields'].forEach (ar_elem_id) ->
            a_elem=form_obj.find("#" + ar_elem_id)

      else
        window['status_block_set_state']($status_container, 'success')
      
  return ret


window['OnFlyEG_Content_UnLoad'] = (frame_id) ->
  frame=$("#" + frame_id)


window['OnFlyEG_Content_OnLoad'] = (frame_id, data) ->
  frame = $("#" + frame_id)

  if((typeof data != "undefined") && (data != null))
    frame_data = $(document.createElement('div'));
    frame_data.html(data)
    if($("meta:first", frame_data).length > 0)


window['button_action'] = (_this, _js, btn_action) ->
  if(_this.length < 1)
    return

  action_url = _this.attr("data-action-url")
  

window['var_unique_id'] = (tag_name) ->
  if((typeof window['varui_' + tag_name] == "undefined") || (window['varui_' + tag_name] == undefined))
    window['varui_' + tag_name] = 1
  window['varui_' + tag_name] = window['varui_' + tag_name] + 1
  return window['varui_' + tag_name]

  
window['status_block_set_state'] = ($status_container, status_class) ->
  if((typeof $status_container != 'undefined') && ($status_container!=null) && ($status_container.length > 0))
    $status_container.addClass(status_class)

window['isMobile'] = () ->
  if(typeof window['isMobile_var'] != "undefined")
    return window['isMobile_var']
  mobiles = ['Android', 'BlackBerry', 'iPhone', 'iPad', 'iPod', 'Opera Mini', 'IEMobile', 'Silk']
  ua = navigator.userAgent || navigator.vendor || window.opera

  for i in [0,mobiles.length-1]
    if(ua.toString().toLowerCase().indexOf(mobiles[i].toLowerCase()) > 0)
      window['isMobile_var'] =  mobiles[i]
      return mobiles[i]
  window['isMobile_var'] = false
  return false


window['show_modal'] = (title, text, button_type, buttons, data_func = null) ->
  
  if(window['isMobile']())
    fade_eff = ''
  else
    fade_eff = 'fade'

  rnd = Math.floor(Math.random() * 10)
  dialog_id = "modal" + rnd + "_" + Date.now()
  modal_html = '<div class="modal ' + fade_eff + '" id="' + dialog_id + '" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true"><div class="modal-dialog" role="document"><div class="modal-content"><div class="modal-header"><h5 class="modal-title" id="exampleModalLabel">' + title + '</h5><button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button></div><div class="modal-body">' + text + '</div><div class="modal-footer">' + buttons + '</div></div></div></div>'
  $("#idbody").append(modal_html)

  $(dialog_id).modal()


window['encodeURIparams'] = (params, with_mark = true) ->
  ret = []
  for d of params
    ret.push(encodeURIComponent(d) + '=' + encodeURIComponent(params[d]))
  if(ret.length != 0)
    str = ret.join('&')
    if(with_mark && (str != ''))
      str = '?' + str
  else
    str = ''
  return str
