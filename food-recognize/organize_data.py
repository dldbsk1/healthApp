import os
import shutil
import random

# 사진을 모아둔 폴더 경로
base_path = "./my_diet_dataset/train"
val_path = "./my_diet_dataset/val"

classes = ["banana", "sweet_potato", "chicken_breast", "cherry_tomato", "boiled_egg"]

for cls in classes:
    src_dir = os.path.join(base_path, cls)
    dst_dir = os.path.join(val_path, cls)
    os.makedirs(dst_dir, exist_ok=True)

    files = [f for f in os.listdir(src_dir) if f.endswith(('.jpg', '.png', '.jpeg'))]
    random.shuffle(files)

    val_count = int(len(files) * 0.2)
    val_files = files[:val_count]

    for f in val_files:
        shutil.move(os.path.join(src_dir, f), os.path.join(dst_dir, f))

    print(f"✅ [{cls}] 완료: {val_count}장을 검증용으로 분리")
