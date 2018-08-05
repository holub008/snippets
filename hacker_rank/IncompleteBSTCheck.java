/**
 * https://www.hackerrank.com/challenges/ctci-is-binary-search-tree/problem
 * Obviously this doesn't compile - code is dropped into a hidden complete implementation on hackerrank 
 * This solution recursively passes a range of acceptable values (according to BST rules) to all subtrees, bubbling up a failure for any invalid subtree
 */


/* Hidden stub code will pass a root argument to the function below. Complete the function to solve the challenge. Hint: you may want to write one or more helper functions.  

The Node class is defined as follows:
    class Node {
        int data;
        Node left;
        Node right;
     }
*/
    boolean checkBST(Node root) {
        return checkBST(root, Integer.MIN_VALUE, Integer.MAX_VALUE);
    }

    boolean checkBST(Node current, int minimumAcceptableValue, int maximumAcceptableValue) {
        if (current == null) {
            return(true);
        }
        else if (current.data < minimumAcceptableValue || current.data > maximumAcceptableValue) {
            return(false);
        }
        else {
            return checkBST(current.left, minimumAcceptableValue, current.data - 1) &&
                checkBST(current.right, current.data + 1, maximumAcceptableValue);
        }
    }
