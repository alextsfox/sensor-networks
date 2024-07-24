using LinearAlgebra
import Random
# using SparseArrays
# using SparseSparse
using SparseArrays
using SparseSparse
using StatsBase
using ProgressBars
using Plots

compute_A(W, alpha) = inv(I - transpose(W))*alpha

compute_H(A, gamma) = sum(A.^gamma)

is_invertible(M) = rank(M) == size(M)[1]

function rewire_node!(W, node, down_node_new)
    @views W[node, :] = sparsevec(Dict(down_node_new => 1.0), size(W)[2])
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
    @views ortho_idx_1 = (X_idx[node_neighbors] .== X_idx[node]) .& (Y_idx[node_neighbors] .== Y_idx[down_node])
    @views ortho_node_1 = node_neighbors[ortho_idx_1]

    @views ortho_idx_2 = (X_idx[node_neighbors] .== X_idx[down_node]) .& (Y_idx[node_neighbors] .== Y_idx[node])
    @views ortho_node_2 = node_neighbors[ortho_idx_2]

    # proposed connection is not diagonal; no crossing is possible
    if (ortho_node_1 == down_node) || (ortho_node_2 == down_node)
        return false
    
    elseif length(ortho_node_1) < 1 || length(ortho_node_2) < 1  # empty, can occur for edge nodes``
        return false
    elseif @views (
        (ortho_node_1[1] <= length(down_nodes)) && (ortho_node_2[1] <= length(down_nodes))  # diagonal
        && (down_nodes[ortho_node_1] == ortho_node_2) || (down_nodes[ortho_node_2] == ortho_node_1)  # crossing
    )
        return true
    end

    return false
end

Random.seed!(1236)
cell_area = 1.0
gamma = 0.5
nrow, ncol = 100, 100
n_iter = nrow*ncol*40
T = exp.(-10*LinRange(0, 1, n_iter))
outlets = [nrow*ncol]
sort!(outlets)


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
down_nodes = Int.(-1*ones(ncol*nrow))
down_nodes[W_nzrow] = W_nzcol[W_nzrow]

A = compute_A(W, alpha)
H = compute_H(A, gamma)
energy = zeros(n_iter)

for i ∈ ProgressBar(1:n_iter)
    valid_rewirings = spzeros(nrow*ncol, nrow*ncol)

    while true
        while true
            W_new = copy(W)
            node = sample(rewireable_nodes)
            @views down_node_new = sample(neighbors[node])
            if @views valid_rewirings[node, down_node_new] == 1
                break
            elseif !is_cross_flow(down_nodes, node, down_node_new, neighbors[node], X_idx, Y_idx)
                rewire_node!(W_new, node, down_node_new)
                if is_invertible(sparse(I - transpose(W_new)))  # slowish
                    valid_rewirings[node, down_node_new] = 1
                    break
                end
            end
        end
        
        A_new = compute_A(W_new, alpha)  # slow
        H_new = compute_H(A_new, gamma)

        if H_new < H
            break
        elseif @views exp(-(H_new - H)/T[i]) > rand()
            break
        end
    end

    energy[i] = H_new
    A = A_new
    H = H_new
    W = copy(W_new)
    
    W_nzrow, W_nzcol, _ = findnz(W)
    down_nodes[W_nzrow] = W_nzcol[W_nzrow]
end
