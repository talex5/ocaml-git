#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let http = Conf.with_pkg "http"
let unix = Conf.with_pkg "unix"
let mirage = Conf.with_pkg "mirage"

let opam = Pkg.opam_file ~lint_deps_excluding:None "opam"

let () =
  Pkg.describe ~opams:[opam] "git" @@ fun c ->
  Ok [
    Pkg.mllib ~api:["Git"] "lib/git.mllib";
    Pkg.mllib "lib/top/git-top.mllib";
  ]
