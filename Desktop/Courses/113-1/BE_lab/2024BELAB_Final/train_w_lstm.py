import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import TensorDataset, DataLoader
import os
import pandas as pd
import time

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# -------------------------
# Hyperparameters
# -------------------------
seq_len = 120       # length of the time series
input_dim = 3       # number of features (alpha, beta, delta)
hidden_dim = 128      # size of LSTM hidden state
num_layers =  2      # number of LSTM layers
num_epochs = 100
batch_size = 16
learning_rate = 0.002

# -------------------------
# Example Data (Replace this with your own data)
# Suppose we have 500 samples for training, each with shape (120, 3)
# and a binary label.
num_train_samples = 450
# num_val_samples = 63

# X_train = torch.randn(num_train_samples, seq_len, input_dim)  # shape (N, 120, 3)
# y_train = torch.randint(0, 2, (num_train_samples,)).float()   # shape (N, )

# X_val = torch.randn(num_val_samples, seq_len, input_dim)
# y_val = torch.randint(0, 2, (num_val_samples,)).float()

input_pth = "output"

#load data in output folder, which is csv files be stored in 32 subfolders
X_data = []
y_data = []
X_train = []
y_train = []
X_val = []
y_val = []

#load data
for sub_dir in os.listdir(input_pth):
    sub_pth = os.path.join(input_pth, sub_dir)
    for file in os.listdir(sub_pth):
        if file.endswith(".csv"):
            file_pth = os.path.join(sub_pth, file)
            # print(f"Loading data from {file_pth}")

            #load data
            df = pd.read_csv(file_pth)
            if len(df) < 120:
                print(f"Data length is less than 120, skip this file.")
                continue
            X_data.append(df.iloc[:, 0:3].values)

            #load label
            filename = file.split(".")[0]
            label = filename.split("_")[1] == "1"
            # print(f"label: {label}")
            y_data.append(torch.tensor(label).float())

            # print("Successfully load data.")

#cut the data into training and validation set
#Normalize the data
X_data = torch.tensor(X_data)
y_data = torch.tensor(y_data)

#normalize the data
X_data = (X_data - X_data.mean()) / X_data.std()

X_train = X_data[:num_train_samples]
y_train = y_data[:num_train_samples]
X_val = X_data[num_train_samples:]
y_val = y_data[num_train_samples:]

print("Successfully load all data.")

print(f"train data check: {y_train.sum()}, {y_train.shape[0]}")
print(f"val data check: {y_val.sum()}, {y_val.shape[0]}")

print("Start training...")

# Create DataLoaders
train_dataset = TensorDataset(X_train, y_train)
train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)

val_dataset = TensorDataset(X_val, y_val)
val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False)

# -------------------------
# Model Definition
# -------------------------
class LSTMClassifier(nn.Module):
    def __init__(self, input_dim, hidden_dim, num_layers=1):
        super(LSTMClassifier, self).__init__()
        self.lstm = nn.LSTM(input_size=input_dim, hidden_size=hidden_dim, 
                            num_layers=num_layers, batch_first=True, dropout=0.2)
        self.fc = nn.Linear(hidden_dim, 1)
        
    def forward(self, x):
        # x: (batch, seq_len, input_dim)
        # LSTM output: (batch, seq_len, hidden_dim), (h_n, c_n)
        x = x.float()
        lstm_out, _ = self.lstm(x)  
        # We can take the output of the last time step for classification
        last_step = lstm_out[:, -1, :]  # shape (batch, hidden_dim)
        logits = self.fc(last_step)     # shape (batch, 1)
        return logits

model = LSTMClassifier(input_dim, hidden_dim, num_layers)
model = model.to(device)  # If you have GPU: model.to('cuda')

# -------------------------
# Loss and Optimizer
# -------------------------
criterion = nn.BCEWithLogitsLoss()
optimizer = optim.Adam(model.parameters(), lr=learning_rate)
scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, 'max', factor=0.5, patience=10)
best_acc = 0
count = 0
acc_list = []

# -------------------------
# Training Loop
# -------------------------
for epoch in range(num_epochs):
    model.train()
    running_loss = 0.0
    correct = 0

    for X_batch, y_batch in train_loader:
        X_batch = X_batch.to(device).float()  # If GPU: X_batch.to('cuda')
        y_batch = y_batch.to(device).unsqueeze(1).float()  # (batch, 1)

        # Forward pass
        outputs = model(X_batch)
        loss = criterion(outputs, y_batch)
        #Normalize the logits
        outputs = torch.sigmoid(outputs)
        pred = (outputs >= 0.5).float()
        correct += (pred == y_batch).sum().item()

        # Backprop
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        running_loss += loss.item() * X_batch.size(0)
    
    scheduler.step(correct / len(train_dataset))

    train_acc = correct / len(train_dataset)
    train_loss = running_loss / len(train_dataset)
    
    # -------------------------
    # Validation Loop
    # -------------------------
    model.eval()
    val_loss = 0.0
    correct = 0
    total = 0
    with torch.no_grad():
        for X_val_batch, y_val_batch in val_loader:
            X_val_batch = X_val_batch.to(device)  # If GPU: X_val_batch.to('cuda')
            y_val_batch = y_val_batch.to(device).unsqueeze(1)

            outputs = model(X_val_batch)
            v_loss = criterion(outputs, y_val_batch)
            val_loss += v_loss.item() * X_val_batch.size(0)

            # Compute accuracy
            outputs = torch.sigmoid(outputs)
            preds = (outputs >= 0.5).float()
            print(f"pred: {preds}")
            # print(f"y_val: {y_val_batch}")
            correct += (preds == y_val_batch).sum().item()
            total += y_val_batch.size(0)

    val_loss = val_loss / len(val_dataset)
    val_acc = correct / total
    acc_list.append(val_acc)
    if val_acc > best_acc:
        best_acc = val_acc
        print(f"Best model so far, save it.")
        torch.save(model.state_dict(), f'./model_path/best_lstm_model_{best_acc:.4f}.pth')

    #Early stopping by checking validation accuracy does not improve after 50 epochs
    if epoch > 50 and val_acc < best_acc:
        count += 1
        if count > 100:
            print(f"Validation accuracy does not improve after 50 epochs, early stopping.")
            break
    else:
        count = 0

    print(f"Epoch [{epoch+1}/{num_epochs}], "
          f"Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.4f}, Val Loss: {val_loss:.4f}, Val Acc: {val_acc:.4f}, lr: {scheduler.get_last_lr()}")
    
print("Training finished.")

#plot the accuracy
import matplotlib.pyplot as plt
plt.plot(acc_list)

# Save the model
t = time.strftime("%Y%m%d-%H%M%S")
torch.save(model.state_dict(), f'./model_path/lstm_model_{t}.pth')
