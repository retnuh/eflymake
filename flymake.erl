-module(flymake).

-export([main/1]).

-define(REBARS, ["..", "../../.."]).

file_exists(FileName) ->
    case file:read_file_info(FileName) of
        {error, _} ->
            false;
        _ ->
            true
    end.

locate_build_tool([]) ->
    not_found;
locate_build_tool([H|T]) ->
    case file_exists(filename:join([H, "rebar"])) of
        true ->
            H;
        false ->
            locate_build_tool(T)
    end.

manual_compile(FileName) ->
    compile:file(FileName, [warn_obsolete_guard, warn_unused_import,
                            warn_shadow_vars, warn_export_vars,
                            strong_validation, report,
                            {i, "../include"},
                            {outdir,filename:join(["/tmp", os:getenv("USER")])}]).

normalize_rebar_error(Err, FileName) ->
    [_|T] = string:tokens(Err, ":"),
    string:join([FileName|T], ":").

rebar_build(FileName, Path) ->
    file:set_cwd(Path),
    Cmd = "./rebar compile 2>&1",
    [_|T] = string:tokens(os:cmd(Cmd), "\n"),
    Errors = [normalize_rebar_error(Err, FileName) || Err <- T],
    lists:foreach(fun(E) -> io:format("~s~n", [E]) end, Errors).

main([FileName]) ->
    case locate_build_tool(?REBARS) of
        not_found ->
            manual_compile(FileName);
        Rebar ->
            rebar_build(FileName, Rebar)
    end.
