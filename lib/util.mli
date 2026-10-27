val err_notify_on_error : string -> (unit, [ `Msg of string ]) result -> unit
(*Propagate encountered error as error notification*)

val warn_notify_on_error : string -> (unit, [ `Msg of string ]) result -> unit
(*Propagate encountered error as warning notification*)
