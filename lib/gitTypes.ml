(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Core_kernel.Std

module SHA1 = struct

  include (String: Identifiable.S)

  module Commit: Identifiable.S = String
  module Tree: Identifiable.S = String
  module Blob: Identifiable.S = String

  let commit c = of_string (Commit.to_string c)
  let to_commit n = Commit.of_string (to_string n)
  let tree t = of_string (Tree.to_string t)
  let blob b = of_string (Blob.to_string b)

  let sha1 str =
    let hash = Cryptokit.Hash.sha1 () in
    hash#add_string str;
    of_string hash#result

  let pretty t =
    GitMisc.hex_encode (to_string t)

end

type sha1 = SHA1.t

module User = struct
  module T = struct
    type t = {
      name : string;
      email: string;
      date : string;
    } with bin_io, compare, sexp
    let hash (t : t) = Hashtbl.hash t
    include Sexpable.To_stringable (struct type nonrec t = t with sexp end)
    let module_name = "User"
  end
  include T
  include Identifiable.Make (T)
end

module Blob: Identifiable.S = String

type blob = Blob.t

module Commit = struct
  module T = struct
    type t = {
      tree     : SHA1.Tree.t;
      parents  : SHA1.Commit.t list;
      author   : User.t;
      committer: User.t;
      message  : string;
    } with bin_io, compare, sexp
    let hash (t : t) = Hashtbl.hash t
    include Sexpable.To_stringable (struct type nonrec t = t with sexp end)
    let module_name = "Commit"
  end
  include T
  include Identifiable.Make (T)
end

type commit = Commit.t

module Tree = struct
  module T = struct
    type entry = {
      perm: [`normal|`exec|`link|`dir];
      file: string;
      node: SHA1.t;
    } with bin_io, compare, sexp
    type t = entry list with bin_io, compare, sexp
    let hash (t: t) = Hashtbl.hash t
    include Sexpable.To_stringable (struct type nonrec t = t with sexp end)
    let module_name = "Tree.Entry"
  end
  include T
  include Identifiable.Make (T)
end

type tree = Tree.t

module Tag = struct
  module T = struct
    type t = {
      commit     : SHA1.Commit.t;
      tag        : string;
      tagger     : User.t;
      tag_message: string;
    } with bin_io, compare, sexp
    let hash (t: t) = Hashtbl.hash t
    include Sexpable.To_stringable (struct type nonrec t = t with sexp end)
    let module_name = "Tag"
  end
  include T
  include Identifiable.Make (T)
end

type tag = Tag.t

module Value = struct
  module T = struct
    type t =
      | Blob   of Blob.t
      | Commit of Commit.t
      | Tag    of Tag.t
      | Tree   of Tree.t
    with bin_io, compare, sexp
    let hash (t: t) = Hashtbl.hash t
    include Sexpable.To_stringable (struct type nonrec t = t with sexp end)
    let module_name = "Value"
  end
  include T
  include Identifiable.Make (T)
end

type value = Value.t

module Packed_value = struct

  type hunk =
    | Insert of string
    | Copy of int * int
  with bin_io, compare, sexp

  type 'a delta = {
    source: 'a;
    source_length: int;
    result_length: int;
    hunks: hunk list;
  } with bin_io, compare, sexp

  module T = struct
    type t =
      | Value     of Value.t
      | Ref_delta of SHA1.t delta
      | Off_delta of int delta
    with bin_io, compare, sexp
    let hash (t: t) = Hashtbl.hash t
    include Sexpable.To_stringable (struct type nonrec t = t with sexp end)
    let module_name = "Value"
  end
  include T
  include Identifiable.Make (T)
end

type packed_value = Packed_value.t

type pack_index = {
  offsets: int SHA1.Map.t;
  lengths: int option SHA1.Map.t;
}

type pack = sha1 -> packed_value

let commit c = Value.Commit c
let blob b = Value.Blob b
let tree t = Value.Tree t
let tag t = Value.Tag t

let value v = Packed_value.Value v
let ref_delta d = Packed_value.Ref_delta d
let off_delta d = Packed_value.Off_delta d

type object_type =
  [ `Blob
  | `Commit
  | `Tag
  | `Tree ]

type successor =
  [ `Commit of sha1
  | `Tag of string * sha1
  | `Tree of string * sha1 ]

let succ = function
  | `Commit s
  | `Tag (_, s)
  | `Tree (_, s) -> s

module type S = sig
  type t
  val create: ?root:string -> unit -> t Lwt.t
  val dump: t -> unit Lwt.t
  val read: t -> sha1 -> value option Lwt.t
  val read_exn: t -> sha1 -> value Lwt.t
  val read_inflated: t -> sha1 -> Mstruct.t option Lwt.t
  val list: t -> sha1 list Lwt.t
  val write: t -> value -> sha1 Lwt.t
  val write_and_check_inflated: t -> sha1 -> string -> unit Lwt.t
  val references: t -> (string * sha1) list Lwt.t
  val write_reference: t -> string -> sha1 -> unit Lwt.t
  val type_of: t -> sha1 -> object_type option Lwt.t
  val succ: t -> sha1 -> successor list Lwt.t
  val expand_filesystem: t -> SHA1.Commit.t -> unit Lwt.t
end
