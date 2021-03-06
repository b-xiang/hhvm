(**
 * Copyright (c) 2015, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)

open Hh_core

let (id_hooks: (Pos.t * string -> Typing_env.env -> unit) list ref) = ref []

(* In this method is_const parameter will always be false, so it's not carrying
 * any new information. It's here to keep the signature of smethod_hooks and
 * cmethod_hooks the same, since more often than not people want to use the
 * same hook for both *)
let (smethod_hooks: (Typing_defs.class_type ->
                     targs:Typing_defs.locl Typing_defs.ty list ->
                     pos_params:Nast.expr list option ->
                     Pos.t * string ->
                     Typing_env.env -> Nast.class_id_ option -> is_method:bool ->
                     is_const:bool -> unit) list ref) = ref []

let (cmethod_hooks: (Typing_defs.class_type ->
                     targs:Typing_defs.locl Typing_defs.ty list ->
                     pos_params:Nast.expr list option ->
                     Pos.t * string ->
                     Typing_env.env -> Nast.class_id_ option -> is_method:bool ->
                     is_const:bool -> unit) list ref) = ref []

let (fun_call_hooks: (Typing_defs.locl Typing_defs.fun_params ->
                      Pos.t list -> Typing_env.env -> unit) list ref) = ref []

let (new_id_hooks: (Nast.class_id_ -> Typing_env.env ->
                    Pos.t -> unit) list ref) = ref []

let (parent_construct_hooks: (Typing_env.env ->
                    Pos.t -> unit) list ref) = ref []

let (enter_method_def_hooks: (Nast.method_ -> unit) list ref) = ref []

let (exit_method_def_hooks: (Nast.method_ -> unit) list ref) = ref []

let (enter_fun_def_hooks: (Nast.fun_ -> unit) list ref) = ref []

let (exit_fun_def_hooks: (Nast.fun_ -> unit) list ref) = ref []

let (enter_class_def_hooks: (Nast.class_ -> Typing_defs.class_type
                            -> unit) list ref) = ref []

let (exit_class_def_hooks: (Nast.class_ -> Typing_defs.class_type
                            -> unit) list ref) = ref []

let attach_smethod_hook hook =
  smethod_hooks := hook :: !smethod_hooks

let attach_cmethod_hook hook =
  cmethod_hooks := hook :: !cmethod_hooks

let attach_id_hook hook =
  id_hooks := hook :: !id_hooks

let attach_new_id_hook hook =
  new_id_hooks := hook :: !new_id_hooks

let attach_parent_construct_hook hook =
  parent_construct_hooks := hook :: !parent_construct_hooks

let attach_method_def_hook enter_hook exit_hook =
  assert (enter_hook <> None || exit_hook <> None);
  (match enter_hook with
  | Some hook ->
      enter_method_def_hooks := hook :: !enter_method_def_hooks
  | None -> ());
  match exit_hook with
  | Some hook ->
      exit_method_def_hooks := hook :: !exit_method_def_hooks
  | None -> ()

let attach_fun_def_hook enter_hook exit_hook =
  assert (enter_hook <> None || exit_hook <> None);
  (match enter_hook with
  | Some hook ->
      enter_fun_def_hooks := hook :: !enter_fun_def_hooks
  | None -> ());
  match exit_hook with
  | Some hook ->
      exit_fun_def_hooks := hook :: !exit_fun_def_hooks
  | None -> ()

let attach_class_def_hook enter_hook exit_hook =
  assert (enter_hook <> None || exit_hook <> None);
  (match enter_hook with
  | Some hook ->
      enter_class_def_hooks := hook :: !enter_class_def_hooks
  | None -> ());
  match exit_hook with
  | Some hook ->
      exit_class_def_hooks := hook :: !exit_class_def_hooks
  | None -> ()

let dispatch_id_hook id env =
  List.iter !id_hooks begin fun hook -> hook id env end

let dispatch_smethod_hook class_ targs ~pos_params id env cid ~is_method
                            ~is_const =
  List.iter !smethod_hooks
    (fun hook -> hook class_ ~targs ~pos_params id env cid ~is_method ~is_const)

let dispatch_cmethod_hook class_ targs ~pos_params id env cid ~is_method =
  List.iter !cmethod_hooks
    (fun hook -> hook class_ ~targs ~pos_params id env cid ~is_method
                   ~is_const:false)

let dispatch_fun_call_hooks ft_params posl env =
  List.iter !fun_call_hooks begin fun hook -> hook ft_params posl env end

let dispatch_new_id_hook cid env p =
  List.iter !new_id_hooks begin fun hook -> hook cid env p end

let dispatch_parent_construct_hook env p =
  List.iter !parent_construct_hooks begin fun hook -> hook env p end

let dispatch_enter_method_def_hook method_ =
  List.iter !enter_method_def_hooks begin fun hook -> hook method_ end

let dispatch_exit_method_def_hook method_ =
  List.iter !exit_method_def_hooks begin fun hook -> hook method_ end

let dispatch_enter_fun_def_hook fun_ =
  List.iter !enter_fun_def_hooks begin fun hook -> hook fun_ end

let dispatch_exit_fun_def_hook fun_ =
  List.iter !exit_fun_def_hooks begin fun hook -> hook fun_ end

let dispatch_enter_class_def_hook cls cls_type =
  List.iter !enter_class_def_hooks begin fun hook -> hook cls cls_type end

let dispatch_exit_class_def_hook cls cls_type =
  List.iter !exit_class_def_hooks begin fun hook -> hook cls cls_type end

let remove_all_hooks () =
  id_hooks := [];
  cmethod_hooks := [];
  smethod_hooks := [];
  fun_call_hooks := [];
  new_id_hooks := [];
  enter_method_def_hooks := [];
  exit_method_def_hooks := [];
  enter_fun_def_hooks := [];
  exit_fun_def_hooks := [];
  enter_class_def_hooks := [];
  exit_class_def_hooks := [];
  parent_construct_hooks := []
