import java.util.*;
import java.io.*;

/**
 * https://www.hackerrank.com/challenges/ctci-queue-using-two-stacks
 * although inefficient compared to e.g. a cyclical array, this a pretty simple & fun queue implementation using two stacks (LIFO)
 */

public class QueueOfStacks  {
    
    public static class MyQueue<T> {
        // using a java.util.Stack over Deque to be more faithful to the problem statement
        private Stack<T> m_pushStack;
        private Stack<T> m_popStack;

        public MyQueue() {
            m_pushStack = new Stack<>();
            m_popStack = new Stack<>();
        }

        private static <T> void swapStacks(Stack<T> stack1, Stack<T> stack2) {
            int stack1Size = stack1.size();
            for (int ix = 0; ix < stack1Size; ix++) {
                stack2.push(stack1.pop());
            }
        }

        public void enqueue(T value) {
            m_pushStack.push(value);
        }
        
        private void prepareForPop() {
            // since our DS is FIFO, we only need to aggregate the queues if the pop stack has been emptied (i.e. the things we want to pop are in the pushStack)
            if (m_popStack.isEmpty()) {
                swapStacks(m_pushStack, m_popStack);
            }
        }

        public void dequeue() {
            prepareForPop();
            m_popStack.pop();
        }

        public T peek() {
            prepareForPop();
            return(m_popStack.peek());
        }
    }
    
    public static void main(String[] args) {
        MyQueue<Integer> queue = new MyQueue<Integer>();

        Scanner scan = new Scanner(System.in);
        int n = scan.nextInt();

        for (int i = 0; i < n; i++) {
            int operation = scan.nextInt();
            if (operation == 1) { // enqueue
              queue.enqueue(scan.nextInt());
            } else if (operation == 2) { // dequeue
              queue.dequeue();
            } else if (operation == 3) { // print/peek
              System.out.println(queue.peek());
            }
        }
        scan.close();
    }
}
