-- This module is intended to be used in the luvit environment, but is still pure lua.
-- and massively scuffed...
local board = {
    a8 = {}, b8 = {}, c8 = {}, d8 = {}, e8 = {}, f8 = {}, g8 = {}, h8 = {},
    a7 = {}, b7 = {}, c7 = {}, d7 = {}, e7 = {}, f7 = {}, g7 = {}, h7 = {},
    a6 = {}, b6 = {}, c6 = {}, d6 = {}, e6 = {}, f6 = {}, g6 = {}, h6 = {},
    a5 = {}, b5 = {}, c5 = {}, d5 = {}, e5 = {}, f5 = {}, g5 = {}, h5 = {},
    a4 = {}, b4 = {}, c4 = {}, d4 = {}, e4 = {}, f4 = {}, g4 = {}, h4 = {},
    a3 = {}, b3 = {}, c3 = {}, d3 = {}, e3 = {}, f3 = {}, g3 = {}, h3 = {},
    a2 = {}, b2 = {}, c2 = {}, d2 = {}, e2 = {}, f2 = {}, g2 = {}, h2 = {},
    a1 = {}, b1 = {}, c1 = {}, d1 = {}, e1 = {}, f1 = {}, g1 = {}, h1 = {},
}

--[[
    for unicode representation
local function RepresentPiece(piece)
    local pieces = {
        white = {
            pawn =  "♟︎",
            rook = "♜",
            knight = "♞",
            bishop = "♟︎",
            queen = "♛",
            king = "♚"
        },
        black = {
            pawn = "♙",
            rook = "♖",
            knight = "♘",
            bishop = "♗",
            queen = "♕",
            king = "♔"
        }
    }
    if piece == "none" then
        return "   "
    else
        return pieces[piece.color][piece.type]
    end
end
]]

local function RepresentPiece(piece)
    -- for use with chessboardimage.com
    local pieces = {
        white = {
            pawn =  "P",
            rook = "R",
            knight = "N",
            bishop = "B",
            queen = "Q",
            king = "K"
        },
        black = {
            pawn = "p",
            rook = "r",
            knight = "n",
            bishop = "b",
            queen = "q",
            king = "k"
        }
    }
    return pieces[piece.color][piece.type]
end

local function in_table(table, thing)
    for i, x in pairs(table) do
        if x == thing then
            return true, i
        end
    end
    return false, nil
end

local function TranslateSpace(coordinates)
    local letters = {"a", "b", "c", "d", "e", "f", "g", "h"}
    if coordinates[2] > 8 or coordinates[2] < 1 then
        return "a9" -- what im returning as an error code essentially (a9 isnt  a space)
    end
    return letters[coordinates[2]]..coordinates[1]
end

local function TranslateCoords(pos)
    local letters = {"a", "b", "c", "d", "e", "f", "g", "h"}
    local letter = string.match(pos, "%a")
    local v = tonumber(string.match(pos, "%d"))
    local h = 0
    for i, p in pairs(letters) do
        if p == letter then
            h = i
        end
    end
    return {vertical = v, horizontal = h}
end

-- piece behaviors
local function pawn(board, piece)
    -- this just isn't consistent with the rest of them huh
    -- en passant at some point in the future ig
    local possibilities = {}
    local h = piece.coordinates.horizontal
    local v = piece.coordinates.vertical
    if piece.color == "white" then
        -- white possibilities
        local up = TranslateSpace({v + 1, h})
        local up_2 = TranslateSpace({v + 2, h})
        local diagRight = TranslateSpace({v + 1, h + 1})
        local diagLeft = TranslateSpace({v + 1, h - 1})
        -- promotion
        if board[up] and (v + 1) == 8 and not board[up].piece then
            table.insert(possibilities, up.."p")
        elseif board[up] and not board[up].piece then
            -- normal up
            table.insert(possibilities, up)
        end
        -- rest
        if board[up_2] and not board[up_2].piece and not piece.lastPosition then
            table.insert(possibilities, up_2)
        end
        if board[diagRight] and board[diagRight].piece and board[diagRight].piece.color ~= piece.color and (v + 1) == 8 then
            table.insert(possibilities, diagRight.."p")
        elseif board[diagRight] and board[diagRight].piece and board[diagRight].piece.color ~= piece.color then
            table.insert(possibilities, diagRight)
        end
        if board[diagLeft] and board[diagLeft].piece and board[diagLeft].piece.color ~= piece.color and (v + 1) == 8 then
            table.insert(possibilities, diagLeft.."p")
        elseif board[diagLeft] and board[diagLeft].piece and board[diagLeft].piece.color ~= piece.color then
            table.insert(possibilities, diagLeft)
        end
    elseif piece.color == "black" then
        -- black possibilities
        local down = TranslateSpace({v - 1, h})
        local down_2 = TranslateSpace({v - 2, h})
        local diagRight = TranslateSpace({v - 1, h + 1})
        local diagLeft = TranslateSpace({v - 1, h - 1})
        -- promotion
        if board[down] and (v - 1) == 1 and not board[down].piece then
            table.insert(possibilities, down.."p")
        elseif board[down] and not board[down].piece then
            -- normal down
            table.insert(possibilities, down)
        end
        if board[down] and not board[down].piece then
            table.insert(possibilities, down)
        end
        if board[down_2] and not board[down_2].piece and not piece.lastPosition then
            table.insert(possibilities, down_2)
        end
        if board[diagRight] and board[diagRight].piece and board[diagRight].piece.color ~= piece.color and (v - 1) == 1 then
            table.insert(possibilities, diagRight.."p")
        elseif board[diagRight] and board[diagRight].piece and board[diagRight].piece.color ~= piece.color then
            table.insert(possibilities, diagRight)
        end
        if board[diagLeft] and board[diagLeft].piece and board[diagLeft].piece.color ~= piece.color and (v - 1) == 1 then
            table.insert(possibilities, diagLeft.."p")
        elseif board[diagLeft] and board[diagLeft].piece and board[diagLeft].piece.color ~= piece.color then
            table.insert(possibilities, diagLeft)
        end
    end
    return possibilities
end

local function knight(board, piece)
    -- Ls up 1 right 2, up 1 left 2, up 2 right 1, up 2 left 1 and backwards as well
    local h = piece.coordinates.horizontal
    local v = piece.coordinates.vertical
    local coord_possibilities = {{v + 1, h + 2}, {v + 1, h - 2}, {v + 2, h + 1}, {v + 2, h - 1}, {v - 1, h + 2}, {v - 1, h - 2}, {v - 2, h + 1}, {v - 2, h - 1}}
    local possibilities = {}
    for i, pos in pairs(coord_possibilities) do
        local space = TranslateSpace(pos)
        if board[space] then
            if board[space].piece and board[space].piece.color ~= piece.color then
                table.insert(possibilities, space)
            end
            table.insert(possibilities, space)
        end
    end
    return possibilities
end

local function rook(board, piece)
    -- all the way horizontally and vertically
    local v = piece.coordinates.vertical
    local h = piece.coordinates.horizontal
    local possibilities = {}
    -- up
    for i = v + 1, 8 do
        local space = TranslateSpace({i, h})
        if board[space] then
            if board[space].piece then
                if board[space].piece.color ~= piece.color then
                    table.insert(possibilities, space)
                end
                break
            else
                table.insert(possibilities, space)
            end
        end
    end
    --down
    for i = v - 1, 1, -1 do
        local space = TranslateSpace({i, h})
        if board[space] then
            if board[space].piece then
                if board[space].piece.color ~= piece.color then
                    table.insert(possibilities, space)
                end
                break
            else
                table.insert(possibilities, space)
            end
        end
    end
    -- right
    for i = h + 1, 8 do
        local space = TranslateSpace({v, i})
        if board[space] then
            if board[space].piece then
                if board[space].piece.color ~= piece.color then
                    table.insert(possibilities, space)
                end
                break
            else
                table.insert(possibilities, space)
            end
        end
    end
    -- left
    for i = h - 1, 1, -1 do
        local space = TranslateSpace({v, i})
        if board[space] then
            if board[space].piece then
                if board[space].piece.color ~= piece.color then
                    table.insert(possibilities, space)
                end
                break
            else
                table.insert(possibilities, space)
            end
        end
    end
    return possibilities
end

local function bishop(board, piece)
    -- diags
    local v = piece.coordinates.vertical
    local h = piece.coordinates.horizontal
    local possibilities = {}
    local count = 1
    -- up right
    for i = v + 1, 8 do
        if (h + count) > 0 and (h + count) < 9 then
            local space = TranslateSpace({i, h + count})
            if board[space].piece ~= nil then
                if board[space].piece.color ~= piece.color then
                    table.insert(possibilities, space)
                end
                break
            else
                table.insert(possibilities, space)
            end
        end
        count = count + 1
    end
    -- up left
    count = 1
    for i = v + 1, 8 do
        if (h - count) > 0 and (h - count) < 9 then
            local space = TranslateSpace({i, h - count})
            if board[space].piece ~= nil then
                if board[space].piece.color ~= piece.color then
                    table.insert(possibilities, space)
                end
                break
            else
                table.insert(possibilities, space)
            end
        end
        count = count + 1
    end
    -- down right
    count = 1
    for i = v - 1, 1, -1 do
        if (h + count) > 0 and (h + count) < 9 then
            local space = TranslateSpace({i, h + count})
            if board[space].piece ~= nil then
                if board[space].piece.color ~= piece.color then
                    table.insert(possibilities, space)
                end
                break
            else
                table.insert(possibilities, space)
            end
        end
        count = count + 1
    end
    -- down left
    count = 1
    for i = v - 1, 1, -1 do
        if (h - count) > 0 and (h - count) < 9 then
            local space = TranslateSpace({i, h - count})
            if board[space].piece ~= nil then
                if board[space].piece.color ~= piece.color then
                    table.insert(possibilities, space)
                end
                break
            else
                table.insert(possibilities, space)
            end
        end
        count = count + 1
    end
    return possibilities
end

local function queen(board, piece)
    -- just run rook and bishop lul
    local possibilities = {}
    for i, pos in pairs(rook(board, piece)) do
        table.insert(possibilities, pos)
    end
    for i, pos in pairs(bishop(board, piece)) do
        table.insert(possibilities, pos)
    end
    return possibilities
end

local function king(board, piece)
    local h = piece.coordinates.horizontal
    local v = piece.coordinates.vertical
    local possibilities = {}
    local coord_possibilities = {{v + 1, h}, {v + 1, h + 1}, {v + 1, h - 1}, {v, h + 1}, {v, h - 1}, {v - 1, h}, {v - 1, h - 1}, {v - 1, h + 1}}
    for i, pos in pairs(coord_possibilities) do
        local space = TranslateSpace(pos)
        if board[space] ~= nil then
            if board[space].piece ~= nil then
                if board[space].piece.color ~= piece.color then
                    table.insert(possibilities, space)
                end
            else
                table.insert(possibilities, space)
            end
        end
    end
    if not piece.lastPosition and board[TranslateSpace{v, h + 1}] and not board[TranslateSpace{v, h + 1}].piece
    and board[TranslateSpace{v, h + 2}] and not board[TranslateSpace{v, h + 2}].piece and board[TranslateSpace{v, h + 3}]
    and board[TranslateSpace{v, h + 3}].piece and board[TranslateSpace{v, h + 3}].piece.type == "rook" and not
    board[TranslateSpace{v, h + 3}].piece.lastPosition then
        table.insert(possibilities, "kc")
    end
    if not piece.lastPosition and board[TranslateSpace{v, h - 1}] and not board[TranslateSpace{v, h - 1}].piece
    and board[TranslateSpace{v, h - 2}] and not board[TranslateSpace{v, h - 2}].piece  and board[TranslateSpace{v, h - 3}] 
    and not board[TranslateSpace{v, h - 3}].piece and board[TranslateSpace{v, h - 4}] and board[TranslateSpace{v, h - 4}].piece
    and board[TranslateSpace{v, h - 4}].piece.type == "rook" and not board[TranslateSpace{v, h - 4}].piece.lastPosition then
        table.insert(possibilities, "qc")
    end
    return possibilities
end

local behaviors = {
    pawn = pawn,
    rook = rook,
    knight = knight,
    bishop = bishop,
    queen = queen,
    king = king,
}

function board:new(old)
    -- create the board object
    local b = old or {}
    setmetatable(b, self)
    self.__index = self
    return b
end

--[[
    for displaying the unicode version
function board:display()
    -- gets a unicode representation of each piece and returns the board as a string
    local outString = "8 "
    local bottomString = "\n   A B C D E F G H"
    for v = 8, 1, -1 do
        for h = 1, 8 do
            local space = TranslateSpace({v, h})
            local piece
            if self[space].piece then
                piece = self[space].piece
            else
                piece = "none"
            end
            outString = outString..RepresentPiece(piece)
        end
        if v > 1 then
            outString = outString.."\n"..(v - 1).." "
        end
    end
    outString = outString..bottomString
    return outString
end
]]

function board:find_king(color)
    for v = 8, 1, -1 do
        for h = 1, 8 do
            local space = TranslateSpace({v, h})
            if self[space] and self[space].piece and self[space].piece.type == "king" and self[space].piece.color == color then
                return space
            end
        end
    end
end

function board:display(color)
    -- uses chessboardimage.com to genereate a board image
    local urlString = "https://chessboardimage.com/"
    for v = 8, 1, -1 do
        local numSincePiece = 0
        for h = 1, 8 do
            local space = TranslateSpace({v, h})
            if self[space].piece then
                if numSincePiece > 0 then
                    urlString = urlString..numSincePiece
                    numSincePiece = 0
                end
                urlString = urlString..RepresentPiece(self[space].piece)
            else
                numSincePiece = numSincePiece + 1
            end
        end
        if numSincePiece > 0 then
            urlString = urlString..numSincePiece
        end
        urlString = urlString.."/"
    end
    if color == "black" then
        urlString = urlString.."-flip"
    end
    urlString = urlString..".png"
    return urlString
end

function board:get_moves(position)
    local piece = self[position].piece
    return behaviors[piece.type](self, piece)
end

function board:get_checks(king)
    -- king is passed as a space since find_king returns a space
    local possibilities = {}
    local kingPiece = self[king].piece
    for v = 1, 8 do
        for h = 1, 8 do
            local space = TranslateSpace({v, h})
            if self[space].piece and self[space].piece.color ~= kingPiece.color then
                for i, pos in pairs(self:get_moves(space)) do
                    table.insert(possibilities, pos)
                end
            end
        end
    end
    if in_table(possibilities, king) then
        return true
    else
        return false
    end
end

function board:move(piece, position)
    --kc for kingside castling
    --qc for queenside castling
    --move on the board. return true if possible
    --promotion is denoted by an appended 'p'
    local promotions = {q = "queen", b = "bishop" , r = "rook", n = "knight"}
    local promotion_piece = "queen"
    local new_pos = position
    local wKingCastle = false
    local wQueenCastle = false
    local bKingCastle = false
    local bQueenCastle = false
    local piecePos = TranslateSpace({piece.coordinates.vertical, piece.coordinates.horizontal})
    local possible_moves = self:get_moves(piecePos) -- no need to update it later.
    if new_pos:len() > 2 and new_pos:sub(3, 3) == "p" then
        if new_pos:len() > 3 and promotions[new_pos:sub(4, 4)] then
            promotion_piece = promotions[new_pos:sub(4, 4)]
        end
        piece.type = promotion_piece
        new_pos = new_pos:sub(1, 3)
    end
    if in_table(possible_moves, new_pos) then
        if new_pos:sub(3, 3) == "p" then
            new_pos = new_pos:sub(1, 2)
        end
        if piece.color == "black" and new_pos == "kc" then
            new_pos = "g8"
            bKingCastle = true
        elseif piece.color == "black" and new_pos == "qc" then
            new_pos = "c8"
            bQueenCastle = true
        elseif piece.color == "white" and new_pos == "kc" then
            new_pos = "g1"
            wKingCastle = true
        elseif piece.color == "white" and new_pos == "qc" then
            new_pos = "c1"
            wQueenCastle = true
        end
        local new_coords
        local removedPiece
        if self[new_pos].piece then
            new_coords = self[new_pos].piece.coordinates
            removedPiece = self[new_pos].piece
        else
            new_coords = TranslateCoords(new_pos)
        end
        self[new_pos].piece = self[piecePos].piece
        self[piecePos].piece.coordinates = new_coords
        self[piecePos].piece = nil
        -- move the rooks if castling
        if wKingCastle then
            self.f1.piece = self.h1.piece
            self.f1.piece.coordinates = TranslateCoords("f1")
            self.h1.piece = nil
        elseif wQueenCastle then
            self.d1.piece = self.a1.piece
            self.d1.piece.coordinates = TranslateCoords("d1")
            self.a1.piece = nil
        elseif bKingCastle then
            self.f8.piece = self.h8.piece
            self.f8.piece.coordinates = TranslateCoords("f8")
            self.h8.piece = nil
        elseif bQueenCastle then
            self.d8.piece = self.a1.piece
            self.d8.piece.coordinates = TranslateCoords("d8")
            self.a8.piece = nil
        end
        -- if it doesn't validate we're fucked because am lazy for now
        return true, removedPiece -- true, nil if no piece was removed, may pass something to indicate castling
    end
    return false, nil
end

function board:RemoveCastle(color, type)
    if type == "kc" then
        if color == "white" then
            -- the white coords
            self.e1.piece = self.g1.piece
            self.e1.piece.coordinates = TranslateCoords("e1")
            self.g1.piece = nil
            self.h1.piece = self.f1.piece
            self.h1.piece.coordinates = TranslateCoords("h1")
            self.f1.piece = nil
        elseif color == "black" then
            -- the black coords
            self.e8.piece = self.g8.piece
            self.e8.piece.coordinates = TranslateCoords("e8")
            self.g8.piece = nil
            self.h8.piece = self.f8.piece
            self.h8.piece.coordinates = TranslateCoords("h8")
            self.f8.piece = nil
        end
    elseif type == "qc" then
        if color == "white" then
            -- the white coords
            self.e1.piece = self.c1.piece
            self.e1.piece.coordinates = TranslateCoords("c1")
            self.c1.piece = nil
            self.a1.piece = self.d1.piece
            self.a1.piece.coordinates = TranslateCoords("a1")
            self.d1.piece = nil
        elseif color == "black" then
            -- the black coords
            self.e8.piece = self.c8.piece
            self.e8.piece.coordinates = TranslateCoords("c8")
            self.c8.piece = nil
            self.a8.piece = self.d8.piece
            self.a8.piece.coordinates = TranslateCoords("a8")
            self.a8.piece = nil
        end
    end
end

function board:remove_promote(origPos, new_pos, type, removed)
    self[origPos].piece = self[new_pos:sub(1, 2)].piece
    self[origPos].piece.type = type
    self[new_pos:sub(1, 2)].piece = removed or nil
    self[origPos].piece.coordinates = TranslateCoords(origPos)
end

-- need to add promotion here and in move
function board:SimulateMove(piece, position)
    local orig_v = piece.coordinates.vertical
    local orig_h = piece.coordinates.horizontal
    local origPos = TranslateSpace({orig_v, orig_h})
    local orig_type = piece.type
    local possible = false
    local tryMove, rem = self:move(piece, position)
    if tryMove then
        if not self:get_checks(self:find_king(piece.color)) then
            possible = true
        end
        if rem then
            if position:len() > 2 and position:sub(3, 3) == "p" then
                self:remove_promote(origPos, position, orig_type, rem)
            else
                self[origPos].piece = self[position].piece
                self[position].piece = rem
                self[origPos].piece.coordinates = TranslateCoords(origPos)
            end
        else
            --checking in case of castling or promotion
            if position == "kc" or position == "qc" then
                -- castle
                self:RemoveCastle(piece.color, position)
            elseif position:len() > 2 and position:sub(3, 3) == "p" then
                -- promotion
                self:remove_promote(origPos, position, orig_type)
            else
                -- normal move
                self[origPos].piece = self[position].piece
                self[position].piece = nil
                self[origPos].piece.coordinates = TranslateCoords(origPos)
            end
        end
    end
    return possible
end

function board:CheckSacs(color)
    -- see which pieces could sacrifice, block, or take in order to get king out of check
    local ret_tab = {}
    for v = 8, 1, -1 do
        for h = 1, 8 do
            local space = TranslateSpace({v, h})
            if self[space] and self[space].piece and self[space].piece.color == color and self[space].piece.type ~= "king" then
                for i, m in pairs(self:get_moves(space)) do
                    if self:SimulateMove(self[space].piece, m) then
                        table.insert(ret_tab, space)
                        break
                    end
                end
            end
        end
    end
    return ret_tab
end

function board:checkmate(king)
    local kingPiece = self[king].piece
    local move_out = {}
    local sacs = {}
    if self:get_checks(king) then
        for i, m in pairs(self:get_moves(king)) do
            local possible = self:SimulateMove(kingPiece, m)
            if possible then
                table.insert(move_out, m)
            end
        end
    end
    sacs = self:CheckSacs(kingPiece.color)
    if #move_out > 0 or #sacs > 0 then
        return false
    end
    return true
end

function board:only_kings()
    -- see if the board is only kings
    for v = 8, 1, -1 do
        for h = 1, 8 do
            local piece = TranslateSpace({v, h})
            if self[piece].piece ~= "king" then
                return false
            end
        end
    end
    return true
end

function board:stalemate()
    if self:only_kings() then
        return true
    end
    local white_king = self:find_king("white")
    local black_king = self:find_king("black")
    if #(self:CheckSacs("white")) == 0 or #(self:CheckSacs("black")) == 0 then
        local white_possible = false
        local black_possible = false
        for move in pairs(self:get_moves(white_king)) do
            if self:SimulateMove(white_king, move) then
                white_possible = true
                break
            end
        end
        for move in pairs(self:get_moves(black_king)) do
            if self:SimulateMove(black_king, move) then
                black_possible = true
                break
            end
        end
        if not white_possible or not black_possible then
            return true
        end
    end
    return false
end

function board:validate_and_move(piece, position)
    -- simulate where moving a piece would put the player. if it puts the player in check, return false. otherwise move and return true.
    local new_pos = position
    local piecePos = TranslateSpace({piece.coordinates.vertical, piece.coordinates.horizontal})
    local possible = self:SimulateMove(self[piecePos].piece, new_pos)
    if possible then
        local moved, removed = self:move(self[piecePos].piece, new_pos)
        piece.lastPosition = piecePos
        return moved, removed
    end
    return false, nil
end

function board:setup()
    -- generate default values for board positions. reset if board already has spaces filled.
    -- will assign a last position for en passant/castling
    -- pawns
    for i = 1, 8 do
        local whiteSpace = TranslateSpace({2, i})
        local blackSpace = TranslateSpace({7, i})
        self[whiteSpace].piece = {type = "pawn", color = "white", coordinates = {vertical = 2, horizontal = i}, --[[behavior = pawn]]}
        self[blackSpace].piece = {type = "pawn", color = "black", coordinates = {vertical = 7, horizontal = i}, --[[behavior = pawn]]}
    end
    -- rooks
    self.a1.piece = {type = "rook", color = "white", coordinates = {vertical = 1, horizontal = 1}, --[[behavior = rook]]}
    self.h1.piece = {type = "rook", color = "white", coordinates = {vertical = 1, horizontal = 8}, --[[behavior = rook]]}
    self.a8.piece = {type = "rook", color = "black", coordinates = {vertical = 8, horizontal = 1}, --[[behavior = rook]]}
    self.h8.piece = {type = "rook", color = "black", coordinates = {vertical = 8, horizontal = 8}, --[[behavior = rook]]}
    -- knights
    self.b1.piece = {type = "knight", color = "white", coordinates = {vertical = 1, horizontal = 2}, --[[behavior = knight]]}
    self.g1.piece = {type = "knight", color = "white", coordinates = {vertical = 1, horizontal = 7}, --[[behavior = knight]]}
    self.b8.piece = {type = "knight", color = "black", coordinates = {vertical = 8, horizontal = 2}, --[[behavior = knight]]}
    self.g8.piece = {type = "knight", color = "black", coordinates = {vertical = 8, horizontal = 7}, --[[behavior = knight]]}
    -- bishops
    self.c1.piece = {type = "bishop", color = "white", coordinates = {vertical = 1, horizontal = 3}, --[[behavior = bishop]]}
    self.f1.piece = {type = "bishop", color = "white", coordinates = {vertical = 1, horizontal = 6}, --[[behavior = bishop]]}
    self.c8.piece = {type = "bishop", color = "black", coordinates = {vertical = 8, horizontal = 3}, --[[behavior = bishop]]}
    self.f8.piece = {type = "bishop", color = "black", coordinates = {vertical = 8, horizontal = 6}, --[[behavior = bishop]]}
    --queens
    self.d1.piece = {type = "queen", color = "white", coordinates = {vertical = 1, horizontal = 4}, --[[behavior = queen]]}
    self.d8.piece = {type = "queen", color = "black", coordinates = {vertical = 8, horizontal = 4}, --[[behavior = queen]]}
    --kings
    self.e1.piece = {type = "king", color = "white", coordinates = {vertical = 1, horizontal = 5},  --[[behavior = king]]}
    self.e8.piece = {type = "king", color = "black", coordinates = {vertical = 8, horizontal = 5},  --[[behavior = king]]}
end

return {
    board = board,
    in_table = in_table,
    RepresentPiece = RepresentPiece,
}