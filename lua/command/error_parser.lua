local M = {}

M.error_table = {
    absoft = {
        regex = '^\\%([Ee]rror on \\|[Ww]arning on\\( \\)\\)\\?[Ll]ine[ \t]\\+\\([0-9]\\+\\)[ \t]\\+of[ \t]\\+"\\?\\([a-zA-Z]\\?:\\?[^":\n]\\+\\)"\\?:',
    },
    ada = {
        regex = '\\(warning: .*\\)\\? at \\([^ \n]\\+\\):\\([0-9]\\+\\)$',
    },
    aix = {
        regex = ' in line \\([0-9]\\+\\) of file \\([^ \n]\\+[^. \n]\\)\\.\\? ',
    },
    ant = {
        regex = '^[ \t]*\\%(\\[[^] \n]\\+\\][ \t]*\\)\\{1,2\\}\\(\\%([A-Za-z]:\\)\\?[^: \n]\\+\\):\\([0-9]\\+\\):\\%(\\([0-9]\\+\\):\\([0-9]\\+\\):\\([0-9]\\+\\):\\)\\?\\( warning\\)\\?',
    },
    bash = {
        regex = '^\\([^: \n\t]\\+\\): line \\([0-9]\\+\\):',
    },
    borland = {
        regex = '^\\%(Error\\|Warnin\\(g\\)\\) \\%([FEW][0-9]\\+ \\)\\?\\([a-zA-Z]\\?:\\?[^:( \t\n]\\+\\) \\([0-9]\\+\\)\\%([) \t]\\|:[^0-9\n]\\)',
    },
    python_tracebacks_and_caml = {
        regex = '^[ \t]*File \\("\\?\\)\\([^," \n\t<>]\\+\\)\\1, lines\\? \\([0-9]\\+\\)-\\?\\([0-9]\\+\\)\\?\\%($\\|,\\%( characters\\? \\([0-9]\\+\\)-\\?\\([0-9]\\+\\)\\?:\\)\\?\\([ \n]Warning\\%( [0-9]\\+\\)\\?:\\)\\?\\)',
    },
    cmake = {
        regex = '^CMake \\%(Error\\|\\(Warning\\)\\) at \\(.*\\):\\([1-9][0-9]*\\) ([^)]\\+):$',
    },
    cmake_info = {
        regex = '^  \\%( \\*\\)\\?\\(.*\\):\\([1-9][0-9]*\\) ([^)]\\+)$',
    },
    comma = {
        regex = '^"\\([^," \n\t]\\+\\)", line \\([0-9]\\+\\)\\%([(. pos]\\+\\([0-9]\\+\\))\\?\\)\\?[:.,; (-]\\( warning:\\|[-0-9 ]*(W)\\)\\?',
    },
    cucumber = {
        regex = '\\%(^cucumber\\%( -p [^[:space:]]\\+\\)\\?\\|#\\)\\%( \\)\\([^(].*\\):\\([1-9][0-9]*\\)',
    },
    msft = {
        regex = '^ *\\([0-9]\\+>\\)\\?\\(\\%([a-zA-Z]:\\)\\?[^ :(\t\n][^:(\t\n]*\\)(\\([0-9]\\+\\)) \\?: \\%(see declaration\\|\\%(warnin\\(g\\)\\|[a-z ]\\+\\) C[0-9]\\+:\\)',
    },
    edg_1 = {
        regex = '^\\([^ \n]\\+\\)(\\([0-9]\\+\\)): \\%(error\\|warnin\\(g\\)\\|remar\\(k\\)\\)',
    },
    edg_2 = {
        regex = 'at line \\([0-9]\\+\\) of "\\([^ \n]\\+\\)"$',
    },
    epc = {
        regex = '^Error [0-9]\\+ at (\\([0-9]\\+\\):\\([^)\n]\\+\\))',
    },
    ftnchek = {
        regex = '\\(^Warning .*\\)\\? line[ \n]\\([0-9]\\+\\)[ \n]\\%(col \\([0-9]\\+\\)[ \n]\\)\\?file \\([^ :;\n]\\+\\)',
    },
    gradle_kotlin = {
        regex = '^\\%(\\(w\\)\\|.\\): *\\(\\%([A-Za-z]:\\)\\?[^:\n]\\+\\): *(\\([0-9]\\+\\), *\\([0-9]\\+\\))',
    },
    iar = {
        regex = '^"\\(.*\\)",\\([0-9]\\+\\)\\s-\\+\\%(Error\\|Warnin\\(g\\)\\)\\[[0-9]\\+\\]:',
    },
    ibm = {
        regex = '^\\([^( \n\t]\\+\\)(\\([0-9]\\+\\):\\([0-9]\\+\\)) : \\%(warnin\\(g\\)\\|informationa\\(l\\)\\)\\?',
    },
    irix = {
        regex = '^[-[:alnum:]_/ ]\\+: \\%(\\%([sS]evere\\|[eE]rror\\|[wW]arnin\\(g\\)\\|[iI]nf\\(o\\)\\)[0-9 ]*: \\)\\?\\([^," \n\t]\\+\\)\\%(, line\\|:\\) \\([0-9]\\+\\):',
    },
    java = {
        regex = '^\\%([ \t]\\+at \\|==[0-9]\\+== \\+\\%(at\\|b\\(y\\)\\)\\).\\+(\\([^()\n]\\+\\):\\([0-9]\\+\\))$',
    },
    jikes_file = {
        regex = '^\\%(Found\\|Issued\\) .* compiling "\\(.\\+\\)":$',
    },
    maven = {
        regex = '^\\%(\\[\\%(ERROR\\|\\(WARNING\\)\\|\\(INFO\\)\\)] \\)\\?\\([^\n []\\%([^\n :]\\| [^\n/-]\\|:[^\n []\\)*\\):\\[\\([[:digit:]]\\+\\),\\([[:digit:]]\\+\\)] ',
    },
    clang_include = {
        regex = '^In file included from \\([^\n:]\\+\\):\\([0-9]\\+\\):$',
        priority = 2,
    },
    gcc_include = {
        regex = '^\\%(In file included \\|                 \\|\t\\)from \\([0-9]*[^0-9\n]\\%([^\n :]\\| [^-/\n]\\|:[^ \n]\\)\\{-}\\):\\([0-9]\\+\\)\\%(:\\([0-9]\\+\\)\\)\\?\\%(\\(:\\)\\|\\(,\\|$\\)\\)\\?',
    },
    ['ruby_Test::Unit'] = {
        regex = '^    [[ ]\\?\\([^ (].*\\):\\([1-9][0-9]*\\)\\(\\]\\)\\?:in ',
    },
    gmake = {
        regex = ': \\*\\*\\* \\[\\%(\\(.\\{-1,}\\):\\([0-9]\\+\\): .\\+\\)\\]',
    },
    gnu = {
        regex = '^\\%([[:alpha:]][-[:alnum:].]\\+: \\?\\|[ \t]\\%(in \\| from\\)\\)\\?\\(\\%([0-9]*[^0-9\\n]\\)\\%([^\\n :]\\| [^-/\\n]\\|:[^ \\n]\\)\\{-}\\)\\%(: \\?\\)\\([0-9]\\+\\)\\%(-\\([0-9]\\+\\)\\%(\\.\\([0-9]\\+\\)\\)\\?\\|[.:]\\([0-9]\\+\\)\\%(-\\%(\\([0-9]\\+\\)\\.\\)\\([0-9]\\+\\)\\)\\?\\)\\?:\\%( *\\(\\%(FutureWarning\\|RuntimeWarning\\|W\\%(arning\\)\\|warning\\)\\)\\| *\\([Ii]nfo\\%(\\>\\|formationa\\?l\\?\\)\\|I:\\|\\[ skipping .\\+ ]\\|instantiated from\\|required from\\|[Nn]ote\\)\\| *\\%([Ee]rror\\)\\|\\%([0-9]\\?\\)\\%([^0-9\\n]\\|$\\)\\|[0-9][0-9][0-9]\\)',
    },
    lcc = {
        regex = '^\\%(E\\|\\(W\\)\\), \\([^(\n]\\+\\)(\\([0-9]\\+\\),[ \t]*\\([0-9]\\+\\)',
    },
    makepp = {
        regex = "^makepp\\%(\\%(: warning\\(:\\).\\{-}\\|\\(: Scanning\\|: [LR]e\\?l\\?oading makefile\\|: Imported\\|log:.\\{-}\\) \\|: .\\{-}\\)`\\(\\(\\S \\{-1,}\\)\\%(:\\([0-9]\\+\\)\\)\\?\\)['(]\\)",
    },
    mips_1 = {
        regex = ' (\\([0-9]\\+\\)) in \\([^ \n]\\+\\)',
    },
    mips_2 = {
        regex = ' in \\([^()\n ]\\+\\)(\\([0-9]\\+\\))$',
    },
    omake = {
        regex = '^\\*\\*\\* omake: file \\(.*\\) changed',
    },
    oracle = {
        regex = '^\\%(Semantic error\\|Error\\|PCC-[0-9]\\+:\\).* line \\([0-9]\\+\\)\\%(\\%(,\\| at\\)\\? column \\([0-9]\\+\\)\\)\\?\\%(,\\| in\\| of\\)\\? file \\(.\\{-}\\):\\?$',
    },
    perl = {
        regex = ' at \\([^ \n]\\+\\) line \\([0-9]\\+\\)\\%([,.]\\|$\\| during global destruction\\.$\\)',
    },
    php = {
        regex = '\\%(Parse\\|Fatal\\) error: \\(.*\\) in \\(.*\\) on line \\([0-9]\\+\\)',
    },
    rxp = {
        regex = '^\\%(Error\\|Warnin\\(g\\)\\):.*\n.* line \\([0-9]\\+\\) char \\([0-9]\\+\\) of file://\\(.\\+\\)',
    },
    sun = {
        regex = ': \\%(ERROR\\|WARNIN\\(G\\)\\|REMAR\\(K\\)\\) \\%([[:alnum:] ]\\+, \\)\\?File = \\(.\\+\\), Line = \\([0-9]\\+\\)\\%(, Column = \\([0-9]\\+\\)\\)\\?',
    },
    sun_ada = {
        regex = '^\\([^, \n\t]\\+\\), line \\([0-9]\\+\\), char \\([0-9]\\+\\)[:., (-]',
    },
    watcom = {
        regex = '^[ \t]*\\(\\%([a-zA-Z]:\\)\\?[^ :(\t\n][^:(\t\n]*\\)(\\([0-9]\\+\\)): \\?\\%(\\(Error! E[0-9]\\+\\)\\|\\(Warning! W[0-9]\\+\\)\\):',
    },
    ['4bsd'] = {
        regex = '\\%(^\\|::  \\|\\S ( \\)\\(/[^ \n\t()]\\+\\)(\\([0-9]\\+\\))\\%(: \\(warning:\\)\\?\\|$\\| ),\\)',
    },
    ['perl__Pod::Checker'] = {
        regex = '^\\*\\*\\* \\%(ERROR\\|\\(WARNING\\)\\).* \\%(at\\|on\\) line \\([0-9]\\+\\) \\%(.* \\)\\?in file \\([^ \t\n]\\+\\)',
    },
}

---Parse a line of text and extract error information using regex patterns
---@param line string The line to parse
---@return table|nil Error information with file, line, and col fields, or nil if no match
function M.parse_line(line)
    if not line or line == '' then
        return nil
    end

    -- Try each error pattern in order
    for pattern_name, pattern in pairs(M.error_table) do
        if pattern.regex then
            -- Use vim.fn.matchlist to get capture groups
            local match = vim.fn.matchlist(line, pattern.regex)

            if match and #match > 0 and match[1] ~= '' then
                -- Extract file, line, and column from capture groups
                local file, lnum, col

                -- Iterate through captures to find file, line number, and column
                for i = 2, #match do
                    local v = match[i]
                    if v and v ~= '' then
                        -- Check if this looks like a file path
                        if not file and (v:match('[/\\]') or v:match('%.%w+$')) then
                            file = v
                        -- Check if this looks like a line number
                        elseif not lnum and v:match('^%d+$') then
                            lnum = tonumber(v)
                        -- Check if this looks like a column number
                        elseif lnum and not col and v:match('^%d+$') then
                            col = tonumber(v)
                        end
                    end
                end

                if file and lnum then
                    return {
                        file = file,
                        line = lnum,
                        col = col or 0,
                    }
                end
            end
        end
    end

    -- Fallback to simple pattern: file:line:col or file:line
    local file, lnum, col = line:match('^([%w%./\\%-_]+):(%d+):?(%d*)')
    if file and lnum then
        return {
            file = file,
            line = tonumber(lnum),
            col = (col and col ~= '' and tonumber(col)) or 0,
        }
    end

    return nil
end

return M
