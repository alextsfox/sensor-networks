using LinearAlgebra
import Random
# using SparseArrays
# using SparseSparse
using SparseArrays
using SparseSparse
using StatsBase
using ProgressBars

compute_A(W, alpha) = inv(I - transpose(W))*alpha

compute_H(H, gamma) = sum(A.^gamma)

is_invertible(M) = rank(M) == size(M)[1]

function rewire_node!(W, node, down_node_new)
    W[node, :] = sparsevec(Dict(node => 1.0), size(W)[2])
end

function get_neighbs_of_i(i, nrow, ncol)
    # UL corner
    if i == 1
        neighbors = [i + 1, i + ncol, i + ncol + 1]

    # UR corner
    elseif i == ncol
        neighbors = [i - 1, i + ncol - 1, i + ncol]
    # LL corner
    elseif i == ncol*(nrow-1) + 1
        neighbors = [i - ncol, i - ncol + 1, i + 1]
    # LR corner
    elseif i == nrow*ncol
        neighbors = [i - ncol - 1, i - ncol, i - 1]
    # left edge
    elseif mod(i, ncol) == 1
        neighbors = [i - ncol, i - ncol + 1, i + 1, i + ncol, i + ncol + 1]
    # right edge
    elseif mod(i, ncol) == 0
        neighbors = [i - ncol - 1, i - ncol, i - 1, i + ncol - 1, i + ncol]
    # top edge
    elseif div(i - 1, ncol) == 0
        neighbors = [i - 1, i + 1, i + ncol - 1, i + ncol, i + ncol + 1]
    # bottom edge
    elseif div(i - 1, ncol) == nrow - 1
        neighbors = [i - ncol - 1, i - ncol, i - ncol + 1, i - 1, i + 1]
    # center
    else
        neighbors = [i - ncol - 1, i - ncol, i - ncol + 1, 
                     i - 1,                         i + 1, 
                     i + ncol - 1, i + ncol, i + ncol + 1]
    end
    
    return neighbors
end

function is_cross_flow(down_nodes, node, down_node, node_neighbors, X_idx, Y_idx)
    ortho_idx_1 = (X_idx[node_neighbors] .== X_idx[node]) .& (Y_idx[node_neighbors] .== Y_idx[down_node])
    ortho_node_1 = node_neighbors[ortho_idx_1]

    ortho_idx_2 = (X_idx[node_neighbors] .== X_idx[down_node]) .& (Y_idx[node_neighbors] .== Y_idx[node])
    ortho_node_2 = node_neighbors[ortho_idx_2]

    # proposed connection is not diagonal; no crossing is possible
    if (ortho_node_1 == down_node) || (ortho_node_2 == down_node)
        return false
    end
    
    # proposed connection is diagonal, need to check for a possible crossing
    # see if the orthogonal nodes are connected. If they are, then our diagonal crossing must cross that path
    # and is invalid
    # print(ortho_node_1, ortho_node_2, down_nodes)
    if (length(ortho_node_1) == 1) && (length(ortho_node_2) == 1) && (ortho_node_1[1] <= length(down_nodes)) && (ortho_node_2[1] <= length(down_nodes))
        if (down_nodes[ortho_node_1] == ortho_node_2) || (down_nodes[ortho_node_2] == ortho_node_1)
            return true
        end
    end
    return false
end

Random.seed!(1234)
cell_area = 1.0
gamma = 0.5
nrow, ncol = 5, 5
n_iter = nrow*ncol*40
T = exp.(-10*LinRange(0, 1, n_iter))
outlets = [nrow*ncol]


alpha = cell_area*ones(nrow*ncol, 1)
X_idx, Y_idx = 1:ncol, 1:nrow
X_idx = vcat(transpose(X_idx * ones(1, nrow))...)
Y_idx = vcat((Y_idx * ones(1, ncol))...)
nodes = 1:nrow*ncol
rewireable_nodes = setdiff(nodes, outlets)
neighbors = [get_neighbs_of_i(i, nrow, ncol) for i in nodes]

W = zeros(nrow*ncol, nrow*ncol)
for i=1:nrow*ncol, j=1:nrow*ncol
    if (div(i-1, ncol) == div(j-1, ncol)) && (j == i + 1)  # j is immediatly to the right of i
        W[i, j] = 1
    end

    if (mod(i, ncol) == 0) && (j == i + ncol)
        W[i, j] = 1
    end
    # if i ==
end

W = sparse(W)
W_nzrow, W_nzcol, _ = findnz(W)
down_nodes = W_nzcol[W_nzrow]

A = compute_A(W, alpha)
H = compute_H(A, gamma)
energy = zeros(n_iter)

for i ∈ ProgressBar(1:n_iter)
    valid_rewirings = spzeros(nrow*ncol, nrow*ncol)


    while true
        while true
            W_new = copy(W)
            node = sample(rewireable_nodes)
            down_node_new = sample(neighbors[node])
            rewire_node!(W_new, node, down_node_new)
            if valid_rewirings[node, down_node_new] == 1
                println("Old Valid")
                break
            elseif !is_cross_flow(down_nodes, node, down_node_new, neighbors[node], X_idx, Y_idx) && is_invertible(sparse(I - transpose(W_new)))
                println("New Valid")
                valid_rewirings[node, down_node_new] = 1
                break
            end
        end
        A_new = compute_A(W_new, alpha)
        H_new = compute_H(A_new, gamma)
        if H_new < H
            println("Better energy")
            print(H_new)
            break
        elseif exp(-(H_new - H)/T[i]) > rand()
            println("Passed MH test")
            print(H_new, " ", exp(-(H_new - H)/T[i]))
            break
        end
        println("Failed MH")
        print(H_new, exp(-(H_new - H)/T[i]))
    end

    energy[i] = H_new
    A = A_new
    W = copy(W_new)
    W_nzrow, W_nzcol, _ = findnz(W)
    down_nodes = W_nzcol[W_nzrow]
end
