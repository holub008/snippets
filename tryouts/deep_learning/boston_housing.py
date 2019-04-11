from keras.datasets import boston_housing
from keras import models
from keras import layers

import numpy as np


import matplotlib.pyplot as plt

(train_data, train_targets), (test_data, test_targets) = boston_housing.load_data()

# standardize features
means = train_data.mean(axis=0)
stds = train_data.std(axis=0)
train_data = (train_data - means) / stds
test_data = (test_data - means) / stds

def build_model():
    model = models.Sequential()
    model.add(layers.Dense(64, activation='relu', input_shape=(train_data.shape[1],)))
    model.add(layers.Dense(64, activation='relu'))
    model.add(layers.Dense(1))

    model.compile(optimizer='rmsprop', loss='mse', metrics=['mae'])
    return model


k = 4
num_val_samples = len(train_data) // k
num_epochs = 500
all_scores = []
all_mae_histories = []

for i in xrange(k):
    val_data = train_data[i * num_val_samples: (i + 1) * num_val_samples]
    val_targets = train_targets[i * num_val_samples: (i + 1) * num_val_samples]

    fold_train_data = np.concatenate([train_data[:i * num_val_samples],
                                      train_data[(i + 1) * num_val_samples:]],
                                     axis=0)
    fold_train_targets = np.concatenate([train_targets[:i * num_val_samples],
                                      train_targets[(i + 1) * num_val_samples:]],
                                     axis=0)
    model = build_model()
    # batch size 1 amounts to stochastic search
    history = model.fit(fold_train_data, fold_train_targets, epochs=num_epochs,
                        validation_data=(val_data, val_targets),
                        batch_size=1, verbose=0)
    mae_history = history.history['val_mean_absolute_error']
    validation_mse, validation_mae = model.evaluate(val_data, val_targets, verbose=0)

    all_scores.append(validation_mae)
    all_mae_histories.append(mae_history)

np.mean(all_scores)


average_mae_history = [
    np.mean([x[i] for x in all_mae_histories]) for i in range(num_epochs)]


def smooth_curve(points, factor=0.9):
  smoothed_points = []
  for point in points:
    if smoothed_points:
      previous = smoothed_points[-1]
      smoothed_points.append(previous * factor + point * (1 - factor))
    else:
      smoothed_points.append(point)
  return smoothed_points
smooth_mae_history = smooth_curve(average_mae_history[10:])

plt.plot(range(1, len(smooth_mae_history) + 1), smooth_mae_history)
plt.xlabel('Epochs')
plt.ylabel('Validation MAE')
plt.show()

# final model with optimal 75 epochs
model = build_model()
model.fit(train_data, train_targets,
          epochs=75, batch_size=16, verbose=0)
test_mse_score, test_mae_score = model.evaluate(test_data, test_targets)