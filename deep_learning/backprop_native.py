from random import random
import math

# this code is loosely based on https://machinelearningmastery.com/implement-backpropagation-algorithm-scratch-python/
# goal is to actually implement backprop in python, as opposed to blindly calling into libraries with minimal understanding of how solutions are computed


# for convenience, only include one hidden layer
def initialize_3_layer_network(input_dimension, hidden_units, output_units):
    # adding a bias weight
    hidden_layer = [{'w':[random() for i in xrange(input_dimension + 1)]} for i in xrange(hidden_units)]
    output_layer = [{'w':[random() for i in xrange(hidden_units + 1)]} for i in xrange(output_units)]

    return [hidden_layer, output_layer]


def sigmoid(x):
    return 1 / (1 + math.exp(-x))


def sigmoid_derivative(x):
    # for a cute little demonstration: https://math.stackexchange.com/questions/78575/
    sx = sigmoid(x)
    return sx * (1 - sx)


# operates on a layer of the network, treating the last element of the weights as the bias
def activate(weights, inputs, f=sigmoid):
    neuron_sum = weights[-1]
    for ix in xrange(len(weights) - 1):
        neuron_sum += weights[ix] * inputs[ix]

    return f(neuron_sum)


# note that this function mutates network (TODO)
def predict(network, observation):
    layer_input = observation
    for layer in network:
        layer_output = []
        for neuron in layer:
            activation = activate(neuron['w'], layer_input)
            neuron['output'] = activation
            layer_output.append(activation)
        layer_input = layer_output

    # this is a bit semantically weird - it's input to an imaginary identity layer :)
    return layer_input


network = initialize_3_layer_network(4, 4, 1)

predict(network, [1, 2, 3, 4])
