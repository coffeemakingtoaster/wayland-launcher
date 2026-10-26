let notifications_max_amount = 10

type level = Info | Warn | Error

type t = {
  start_time_ms : int64;
  message : string;
  level : level;
  wanted_ttl_ms : int64;
  fade_out_time_ms : int64;
}

let notification_list : t list ref = ref []

let ttl_from_severity ~(severity : level) =
  match severity with Info -> 3000L | Warn -> 5000L | Error -> 10000L

let get_notifications () =
  let now = Int64.of_float (Unix.gettimeofday () *. 1000.0) in
  let filter n =
    Int64.compare
      (Int64.sub now n.start_time_ms)
      (Int64.add n.wanted_ttl_ms n.fade_out_time_ms)
    < 0
  in
  List.take_while filter !notification_list

let get_fade_out_progress ~(notification : t) =
  let now = Int64.of_float (Unix.gettimeofday () *. 1000.0) in
  let runtime_ms = Int64.sub now notification.start_time_ms in
  let fade_out_time_ms = Int64.sub runtime_ms notification.wanted_ttl_ms in
  Float.max (Int64.to_float fade_out_time_ms) 0.0
  /. Int64.to_float notification.fade_out_time_ms

let add_notification ~(message : string) ~(level : level) =
  notification_list :=
    List.take notifications_max_amount
      ({
         start_time_ms = Int64.of_float (Unix.gettimeofday () *. 1000.0);
         message;
         level;
         wanted_ttl_ms = ttl_from_severity ~severity:level;
         fade_out_time_ms = 300L;
       }
      :: !notification_list)

let color_from_severity ~(severity : level) =
  match severity with
  | Info -> (255, 255, 255)
  | Warn -> (255, 255, 0)
  | Error -> (255, 0, 0)
