let notify_on_error level message = function
  | Ok _ -> ()
  | Error (`Msg e) ->
      Notifications.add_notification
        ~message:(Printf.sprintf "%s: %s" message e)
        ~level

let err_notify_on_error = notify_on_error Notifications.Error
let warn_notify_on_error = notify_on_error Notifications.Warn

let err_log_on_error = function
  | Ok _ -> ()
  | Error (`Msg e) -> Printf.eprintf "Error: %s" e
