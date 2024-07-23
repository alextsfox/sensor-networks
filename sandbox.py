
# import dask.dataframe as ddf
import numpy as np
# import matplotlib.pyplot as plt
# from tqdm.notebook import tqdm
from tqdm import trange
from time import perf_counter as timer
import matplotlib.pyplot as plt

def compute_A(W, alpha):
    return np.linalg.inv(np.eye(W.shape[0]) - W.T)@alpha
def compute_H(A, gamma):
    return (A**gamma).sum()

def is_cross_flow(down_nodes, node, down_node, node_neighbors, X_idx, Y_idx):
    """Detects if a proposed path will result in cross streamlines
    Parameters
    ----------
    down_nodes: list of downstream node for each node in nodes.
    node: integer representing the source node
    down_node: integer representing the downstream node to connect node to
    node_neighbors: list of integers representing the neighbors of node 
    X_idx: list of X coordinates
    Y_idx: list of Y coordinates

    Returns
    -------
    False if no crossing is detected, True if a crossing is detected
    """
    # first, we detect if the path is diagonal
    
    # find neighboring nodes in the downstream direction that share the same X or Y coordinate.
    # these nodes are referred to as "orthogonal" nodes, and a connection to these nodes is not diagonal.
    ortho_idx_1 = (X_idx[node_neighbors] == X_idx[node]) & (Y_idx[node_neighbors] == Y_idx[down_node])
    ortho_node_1 = node_neighbors[ortho_idx_1]

    ortho_idx_2 = (X_idx[node_neighbors] == X_idx[down_node]) & (Y_idx[node_neighbors] == Y_idx[node])
    ortho_node_2 = node_neighbors[ortho_idx_2]

    # proposed connection is not diagonal; no crossing is possible
    if (ortho_node_1 == down_node) or (ortho_node_2 == down_node):
        return False
    
    # proposed connection is diagonal, need to check for a possible crossing
    # see if the orthogonal nodes are connected. If they are, then our diagonal crossing must cross that path
    # and is invalid
    if (down_nodes[ortho_node_1] == ortho_node_2) or (down_nodes[ortho_node_2] == ortho_node_1):
        return True

    return False
    

def get_neighbs_of_i(i, nrow, ncol):
    # UL corner
    if i == 0:
        neighbors = np.array([                 i + 1, 
                            i + ncol, i + ncol + 1])
    # UR corner
    elif i == ncol - 1:
        neighbors = np.array([i - 1, 
                            i + ncol - 1, i + ncol])
    # LL corner
    elif i == ncol*nrow - ncol:
        neighbors = np.array([i - ncol, i - ncol + 1, 
                                            i + 1])
    # LR corner
    elif i == nrow*ncol - 1:
        neighbors = np.array([i - ncol - 1, i - ncol, 
                            i - 1])
    # left edge
    elif i%ncol == 0:
        neighbors = np.array([i - ncol, i - ncol + 1, 
                                            i + 1, 
                            i + ncol, i + ncol + 1])
    # right edge
    elif (i + 1)%ncol == 0:
        neighbors = np.array([i - ncol - 1, i - ncol, 
                            i - 1, 
                            i + ncol - 1, i + ncol])
    # top edge
    elif i//ncol == 0:
        neighbors = np.array([i - 1,                         i + 1, 
                            i + ncol - 1, i + ncol, i + ncol + 1])
    # bottom edge
    elif i//ncol + 1 == ncol:
        neighbors = np.array([i - ncol - 1, i - ncol, i - ncol + 1, 
                            i - 1,                         i + 1])
    # center
    else:
        neighbors = np.array([i - ncol - 1, i - ncol, i - ncol + 1, 
                            i - 1,                         i + 1, 
                            i + ncol - 1, i + ncol, i + ncol + 1])
    return neighbors

def is_invertible(M):
    try:
        _ = np.linalg.inv(M)
        inv = True
    except np.linalg.LinAlgError:
        inv = False
    return inv

def rewire_node(W, node_to_rewire, candidate_path):
    W[node_to_rewire, :] = 0
    W[node_to_rewire, candidate_path] = 1
    return

if __name__ == "__main__":
    rng = np.random.default_rng(0)
    cell_area = 1.0
    gamma = 0.5
    nrow, ncol = 10, 10
    n_iter = nrow*ncol*40
    alpha = cell_area*np.ones((nrow*ncol, 1))

    X_idx, Y_idx = np.meshgrid(np.arange(ncol), np.arange(nrow))
    X_idx, Y_idx = X_idx.flatten(), Y_idx.flatten()

    T = np.exp(-10*np.linspace(0, 1, n_iter))

    # building the initial condition
    outlets = [nrow*ncol-1]
    W = np.zeros((nrow*ncol, nrow*ncol), dtype=int)
    for i in range(nrow*ncol):
        for j in range(nrow*ncol):
            if (
                i//ncol == j//ncol 
                and i != j 
                and j == i + 1
            ):
                W[i, j] = 1
            if (
                (i + 1)%ncol == 0
                and j == i + ncol
            ):
                W[i, j] = 1
    nodes = np.arange(W.shape[0])
    rewireable_nodes = np.setdiff1d(nodes, outlets)
    neighbors = [get_neighbs_of_i(i, nrow, ncol) for i in nodes]

    down_nodes = [np.where(row)[0][0] for row in W[rewireable_nodes]]
    for i in outlets: down_nodes.insert(i, -1)
    down_nodes = np.array(down_nodes)

    times = dict(
        copying=[0, 0],
        rng=[0, 0],
        rewiring=[0, 0],
        check_valid=[0, 0],
        check_invertible=[0, 0],
        check_failed=[0, 0],
        compute_A=[0, 0],
        compute_H=[0, 0],
        valid_attempts=0,
        mh_attempts=0,
    )

    energy = np.full(n_iter, np.nan)

    
    for i in trange(n_iter):
        valid_rewirings = np.zeros_like(W)
        while True:  # Metro Hastings loop
            while True:  # invertibility loop

                t0 = timer()
                W_new = W.copy()
                t1 = timer()
                times["copying"][0] += t1 - t0
                times["copying"][1] += 1

                t0 = timer()
                node = rng.choice(rewireable_nodes)
                down_node_new = rng.choice(neighbors[node])
                t1 = timer()
                times["rng"][0] += t1 - t0
                times["rng"][1] += 1

                t0 = timer()
                rewire_node(W_new, node, down_node_new)
                t1 = timer()
                times["rewiring"][0] += t1 - t0
                times["rewiring"][1] += 1
                
                t0 = timer()
                if valid_rewirings[node, down_node_new]:
                    t1 = timer()
                    times["check_valid"][0] += t1 - t0
                    times["check_valid"][1] += 1
                    break



                elif (
                    is_invertible(np.eye(W_new.shape[0]) - W_new.T) and
                    not is_cross_flow(down_nodes, node, down_node_new, neighbors[node], X_idx, Y_idx)
                ): 
                    t1 = timer()
                    valid_rewirings[node, down_node_new] = 1
                    times["check_invertible"][0] += t1 - t0
                    times["check_invertible"][1] += 1
                    break
                t1 = timer()
                times["check_failed"][0] += t1 - t0
                times["check_failed"][1] += 1


            # compute new energy
            A = compute_A(W, alpha)
            H = compute_H(A, gamma)

            A_new = compute_A(W_new, alpha)
            H_new = compute_H(A_new, gamma)
            if H_new < H:
                break
            elif np.exp(-(H_new - H)/T[i]) > rng.uniform(0, 1):
                break

        energy[i] = H_new
        A = A_new
        W = W_new.copy()
        down_nodes = [np.where(row)[0][0] for row in W[rewireable_nodes]]
        for i in outlets: down_nodes.insert(i, -1)
        down_nodes = np.array(down_nodes)

    for k, v in times.items():
        print(k, ":", v)

    
    def draw_W(W, ncol, A):
        x, y, u, v, width = [], [], [], [], []
        for i in range(W.shape[0]):
            irow, icol = i//ncol, i%ncol
            for j in range(W.shape[1]):
                jrow, jcol = j//ncol, j%ncol
                if W[i, j]:
                    x.append(icol)
                    y.append(irow)
                    u.append(jcol - icol)
                    v.append(jrow - irow)
                    width.append(A[i, 0])
                    plt.plot([icol, jcol], [irow, jrow], lw=np.sqrt(A[i, 0]/A.max())*3, color="C0")
            
