from keras.layers import Dense
from keras.models import Sequential
import numpy as np

model = Sequential()
model.add(Dense(64, input_shape=(1,), activation='relu'))
model.add(Dense(16))
model.add(Dense(8))
model.add(Dense(1))
x_train = []
y_train = []
pi = 3.14159265358979323846
for x in range(40000):
    r = np.random.randint(0, 40000)
    x_train.append(r)
    y_train.append(pi*r*r)
model.summary()
# sgd = optimizers.SGD(lr=0.01)
# model.compile(optimizer=sgd, loss='mean_squared_error', metrics=['accuracy'])
model.compile(optimizer="adamax", loss='mean_squared_error', metrics=['accuracy'])
history = model.fit(x=np.array(x_train), y=np.array(y_train), batch_size=16, validation_split=0.25, nb_epoch=10)

history.history

model.predict(np.array(x_train))
np.array(x_train) ** 2 * pi

model_sgd = Sequential()
model_sgd.add(Dense(2, input_shape=(1, ), activation='relu'))
model_sgd.add(Dense(2))
model_sgd.add(Dense(1))

model_sgd.compile(optimizer='sgd', loss='mean_squared_error', metrics=['accuracy'])
history_sgd =  model_sgd.fit(x=np.array(x_train), y=np.array(y_train), batch_size=16, validation_split=0.25, nb_epoch=10)

model_sgd.predict(np.array(x_train))