let notifications_max_amount = 3

type notification_severity_level = INFO | WARN | ERROR

type notification = {
  start_time_ms : int64;
  message : string;
  level : notification_severity_level;
  wanted_ttl_ms : int64;
  fade_out_time_ms : int64;
}

let notification_list : notification list ref = ref []

let ttl_from_severity ~(severity : notification_severity_level) =
  match severity with INFO -> 3000L | WARN -> 5000L | ERROR -> 10000L

let get_notifications () =
  let now = Int64.of_float (Unix.gettimeofday () *. 1000.0) in
  let filter n =
    Int64.compare
      (Int64.sub now n.start_time_ms)
      (Int64.add n.wanted_ttl_ms n.fade_out_time_ms)
    < 0
  in
  List.take_while filter !notification_list

let add_notification ~(message : string) ~(level : notification_severity_level)
    =
  notification_list :=
    List.take notifications_max_amount
      ({
         start_time_ms = Int64.of_float (Unix.gettimeofday () *. 1000.0);
         message;
         level;
         wanted_ttl_ms = ttl_from_severity ~severity:level;
         fade_out_time_ms = 1000L;
       }
      :: !notification_list)

let color_from_severity ~(severity : notification_severity_level) =
  match severity with
  | INFO -> (255, 255, 255)
  | WARN -> (255, 255, 0)
  | ERROR -> (255, 0, 0)
