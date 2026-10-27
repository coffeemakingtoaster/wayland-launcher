let notify_on_error level message = function
  | Ok () -> ()
  | Error (`Msg e) ->
      Notifications.add_notification
        ~message:(Printf.sprintf "%s: %s" message e)
        ~level

let err_notify_on_error = notify_on_error Notifications.Error
let warn_notify_on_error = notify_on_error Notifications.Warn
