(*
 * Copyright (c) 2013-2015 Thomas Gazagnaire <thomas@gazagnaire.org>
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

(** Filesystem trees. *)

type perm =
  [ `Normal
  | `Exec
  | `Link
  | `Dir
  | `Commit ]
(** File permission. *)

val pretty_perm: perm -> string
(** Pretty printing of tree permissions. *)

val string_of_perm : perm -> string
(** Raw represention of a permission, using the [Git] format. *)

val fixed_length_string_of_perm : perm -> string
(** Fixed-length raw represention of a permission, using the [Git] format (6 characters long). *)

type entry = {
  perm: perm;
  name: string;
  node: SHA.t;
}
(** A tree entry. This is either a directory or a file. As this is
    supposed to model a filesystem, directory does not contain
    data. *)

type t = entry list
(** A tree is an hierarchical data-store. NB: data (eg. blobs) are
    only carried on the leafs. *)

include Object.S with type t := t

module IO (D: SHA.DIGEST): Object.IO with type t = t
