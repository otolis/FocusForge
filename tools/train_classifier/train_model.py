"""Train a TFLite text classification model for task categorization.

This script trains an average word embedding text classifier using
TensorFlow Lite Model Maker. The trained model is exported as a
.tflite file along with vocabulary and label files, ready to be
bundled as Flutter app assets.

Usage:
    pip install -r requirements.txt
    python train_model.py

Output:
    ../../assets/ml/task_classifier.tflite
    ../../assets/ml/task_classifier_vocab.txt (updated)
    ../../assets/ml/task_classifier_labels.txt (updated)

Categories:
    work, personal, health, shopping, finance, education, errands, social
"""

import os
import csv

# Note: tflite-model-maker requires specific TensorFlow version.
# If tflite-model-maker is unavailable, a fallback message is shown.
try:
    from tflite_model_maker import text_classifier
    from tflite_model_maker.text_classifier import DataLoader

    USE_MODEL_MAKER = True
except ImportError:
    USE_MODEL_MAKER = False

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(SCRIPT_DIR, "training_data.csv")
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "..", "..", "assets", "ml")


def validate_training_data():
    """Validate the training data CSV before training."""
    if not os.path.exists(DATA_FILE):
        raise FileNotFoundError(f"Training data not found: {DATA_FILE}")

    category_counts = {}
    total_rows = 0

    with open(DATA_FILE, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            category = row["category"].strip()
            category_counts[category] = category_counts.get(category, 0) + 1
            total_rows += 1

    print(f"Total training examples: {total_rows}")
    print(f"Categories ({len(category_counts)}):")
    for cat, count in sorted(category_counts.items()):
        print(f"  {cat}: {count} examples")

    if total_rows < 200:
        print(f"WARNING: Only {total_rows} examples. Recommend 200+ for better accuracy.")

    min_examples = min(category_counts.values())
    if min_examples < 20:
        print(f"WARNING: Smallest category has only {min_examples} examples. Consider adding more.")

    return total_rows, category_counts


def train_with_model_maker():
    """Train using TF Lite Model Maker (recommended approach)."""
    print("Loading training data...")
    data = DataLoader.from_csv(
        filename=DATA_FILE,
        text_column="text",
        label_column="category",
        delimiter=",",
        is_training=True,
    )

    train_data, test_data = data.split(0.8)
    print(f"Training examples: {len(train_data)}, Test examples: {len(test_data)}")

    print("Training model (average word embedding)...")
    model = text_classifier.create(
        train_data,
        model_spec="average_word_vec",
        epochs=50,
        batch_size=32,
    )

    print("Evaluating model...")
    loss, accuracy = model.evaluate(test_data)
    print(f"Test loss: {loss:.4f}, Test accuracy: {accuracy:.4f}")

    print(f"Exporting model to {OUTPUT_DIR}...")
    model.export(
        export_dir=OUTPUT_DIR,
        export_format=[
            text_classifier.ExportFormat.TFLITE,
            text_classifier.ExportFormat.VOCAB,
            text_classifier.ExportFormat.LABEL,
        ],
    )
    print(f"Model exported successfully to {OUTPUT_DIR}")
    print("Files created:")
    print(f"  - {os.path.join(OUTPUT_DIR, 'task_classifier.tflite')}")
    print(f"  - {os.path.join(OUTPUT_DIR, 'task_classifier_vocab.txt')}")
    print(f"  - {os.path.join(OUTPUT_DIR, 'task_classifier_labels.txt')}")


if __name__ == "__main__":
    print("=" * 60)
    print("FocusForge Task Classifier Training Pipeline")
    print("=" * 60)

    # Validate data
    total, categories = validate_training_data()
    print()

    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    if USE_MODEL_MAKER:
        train_with_model_maker()
    else:
        print("ERROR: tflite-model-maker is not installed.")
        print()
        print("To train the model, install dependencies:")
        print("  pip install -r requirements.txt")
        print()
        print("Note: tflite-model-maker requires Python 3.8-3.11 and")
        print("TensorFlow 2.15.x - 2.16.x. Consider using a virtual")
        print("environment or conda:")
        print()
        print("  python -m venv venv")
        print("  source venv/bin/activate  # or venv\\Scripts\\activate on Windows")
        print("  pip install -r requirements.txt")
        print("  python train_model.py")
