import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

# Load your simulated data
df = pd.read_csv('garage_data.csv')  # or use the one we generated

X = df[['distanceToClass', 'distanceFromOrigin', 'availableSpaces']]
y = df['selected']

# Split into train/test
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# Train the model
model = LogisticRegression()
model.fit(X_train, y_train)

# Print the model coefficients (these go into Dart later)
print("Weights:", model.coef_)
print("Bias:", model.intercept_)

# Evaluate performance
predictions = model.predict(X_test)
print(classification_report(y_test, predictions))
