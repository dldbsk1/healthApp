import os
from fastapi import FastAPI, File, UploadFile, Form
from typing import Optional
import uvicorn
import torch
from PIL import Image
import cv2
import numpy as np
from ultralytics import YOLO, YOLOE
import torch.nn as nn
from torchvision import transforms
from transformers import AutoModel  # DINOv2 백본 로드용

# ==========================================
# FastAPI 앱 초기화
# ==========================================
app = FastAPI(title="DietTotalAI Server v3 — Spoon Scale + YOLOE + ARKit Thickness")

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


# ==========================================
# 숟가락 전용 감지기
# ==========================================
class SpoonDetector:
    SPOON_REAL_LENGTH_MM = 220.0  # 한국 표준 식사 숟가락 길이

    # 💡 [개선] 숟가락 "박스의 대각선" 대신, 숟가락 마스크를 감싸는 "회전 사각형의 긴 변"을 길이로 사용.
    # 축 정렬 박스는 숟가락이 비스듬히 놓이면 대각선이 실제 길이보다 크게 잡혀
    # 스케일(mm/px)이 작아지고, 면적(스케일의 제곱)과 무게가 가볍게 계산되는 문제가 있었음.
    CONF_THRESHOLD = 0.30     # 이보다 낮은 신뢰도의 검출은 무시 (기본값 0.25였음)
    MIN_ASPECT_RATIO = 2.5    # 긴 변 / 짧은 변 — 이보다 뭉툭하면 숟가락이 아닌 것으로 봄
    MAX_ASPECT_RATIO = 10.0   # 이보다 가늘면(젓가락 등) 숟가락이 아닌 것으로 봄
    MIN_LENGTH_RATIO = 0.08   # 긴 변이 사진 긴 쪽의 8%보다 짧으면 오검출로 봄
    EDGE_MARGIN_PX = 3        # 사진 가장자리에 닿아 잘린 숟가락은 길이를 믿을 수 없어 제외

    def __init__(self, weights_path=None):
        # 세그멘테이션 가중치를 사용 (환경변수 SPOON_WEIGHTS로 바꿀 수 있음. 예: yolov8s-seg.pt)
        weights_path = weights_path or os.getenv("SPOON_WEIGHTS", "yolov8n-seg.pt")
        print(f" Spoon Detector Loading... [Device: {device}, Weights: {weights_path}]")
        self.model = YOLO(weights_path)
        self.spoon_class_idx = [
            k for k, v in self.model.names.items() if v == 'spoon'
        ][0]
        print(" Spoon Detector Ready")

    @staticmethod
    def oriented_size_px(contour):
        """마스크 윤곽을 감싸는 가장 작은 회전 사각형의 (긴 변, 짧은 변) 픽셀 길이. 계산 불가면 None."""
        pts = np.asarray(contour, dtype=np.float32).reshape(-1, 2)
        if len(pts) < 5:
            return None
        (_, _), (w, h), _ = cv2.minAreaRect(pts)
        long_side, short_side = max(w, h), min(w, h)
        if short_side <= 0:
            return None
        return float(long_side), float(short_side)

    def detect(self, img):
        """숟가락을 찾아 {"bbox": [x1,y1,x2,y2], "length_px": 긴 변 픽셀, "conf": 신뢰도}를 돌려줌. 없으면 None."""
        results = self.model(
            img, device=device, classes=[self.spoon_class_idx],
            conf=self.CONF_THRESHOLD, verbose=False
        )
        if not results:
            return None
        result = results[0]
        if result.masks is None or len(result.boxes) == 0:
            return None

        h_img, w_img = img.shape[:2]
        # 신뢰도 높은 순서로 검사해서 조건을 모두 통과하는 첫 번째 숟가락을 사용
        order = torch.argsort(result.boxes.conf, descending=True).tolist()
        for i in order:
            size = self.oriented_size_px(result.masks.xy[i])   # 원본 이미지 픽셀 좌표의 윤곽
            if size is None:
                continue
            long_side, short_side = size
            aspect = long_side / short_side

            x1, y1, x2, y2 = result.boxes.xyxy[i].tolist()
            conf = float(result.boxes.conf[i])

            if not (self.MIN_ASPECT_RATIO <= aspect <= self.MAX_ASPECT_RATIO):
                print(f" 🥄 [숟가락 후보 제외] 가로세로 비율 {aspect:.1f} (conf={conf:.2f})")
                continue
            if long_side < self.MIN_LENGTH_RATIO * max(h_img, w_img):
                print(f" 🥄 [숟가락 후보 제외] 너무 작음 {long_side:.0f}px (conf={conf:.2f})")
                continue
            m = self.EDGE_MARGIN_PX
            if x1 <= m or y1 <= m or x2 >= w_img - m or y2 >= h_img - m:
                print(f" 🥄 [숟가락 후보 제외] 사진 가장자리에서 잘림 (conf={conf:.2f})")
                continue

            print(f" 🥄 [숟가락] conf={conf:.2f}, 긴 변={long_side:.1f}px, 비율={aspect:.1f}")
            return {"bbox": [x1, y1, x2, y2], "length_px": long_side, "conf": conf}
        return None

    def compute_scale_factor(self, spoon_length_px):
        """숟가락 긴 변(픽셀) → 실제 220mm 환산 → 1픽셀당 mm 반환"""
        if spoon_length_px is None or spoon_length_px <= 0:
            return None
        return self.SPOON_REAL_LENGTH_MM / float(spoon_length_px)


# ==========================================
# YOLOE 통합 분할기 — 음식/그릇 구별
# ==========================================
class FoodVsBowlSegmenter:
    FOOD_PROMPTS = [
        "food", "fruit", "meat", "poultry", "vegetable", "egg", "bread"
    ]
    CONTAINER_PROMPTS = [
        "bowl", "plate", "dish", "tray",
        "container", "cup", "glass bowl", "plastic container",
    ]

    def __init__(self, weights_path="yoloe-v8s-seg.pt"):
        print(f" YOLOE Segmenter Loading... [Device: {device}]")
        self.model = YOLOE(weights_path)

        all_prompts = self.FOOD_PROMPTS + self.CONTAINER_PROMPTS
        self.model.set_classes(all_prompts, self.model.get_text_pe(all_prompts))
        self.all_prompts = all_prompts
        print(f" YOLOE Segmenter Ready (Food {len(self.FOOD_PROMPTS)}종 + Bowl {len(self.CONTAINER_PROMPTS)}종)")

    def detect(self, img):
        results = self.model(img, device=device, conf=0.20, retina_masks=True, verbose=False)
        food_objects = []
        filtered_containers = []

        for result in results:
            if result.masks is None:
                continue
            boxes = result.boxes.xyxy.cpu().numpy()
            masks = result.masks.data.cpu().numpy()
            classes = result.boxes.cls.cpu().numpy()
            confs = result.boxes.conf.cpu().numpy()
            names = result.names
            sorted_indices = np.argsort(-confs)

            for idx in sorted_indices:
                class_name = names[int(classes[idx])].lower()
                conf = float(confs[idx])
                if class_name in self.CONTAINER_PROMPTS:
                    print(f"   [Filtering] {class_name} (conf={conf:.2f}) -> 그릇 제외")
                    mask_resized = cv2.resize(masks[idx], (img.shape[1], img.shape[0]), interpolation=cv2.INTER_NEAREST)
                    filtered_containers.append({
                        "bbox": [int(x) for x in boxes[idx]], "mask": mask_resized,
                        "conf": conf, "raw_class": class_name,
                    })
                    continue
                if class_name in self.FOOD_PROMPTS:
                    print(f"   [Detecting] {class_name} (conf={conf:.2f}) -> 음식 통과")
                    mask_resized = cv2.resize(masks[idx], (img.shape[1], img.shape[0]), interpolation=cv2.INTER_NEAREST)
                    food_objects.append({
                        "bbox": [int(x) for x in boxes[idx]], "mask": mask_resized,
                        "conf": conf, "raw_class": class_name,
                    })
                else:
                    print(f"   ❓ [Unclassified] {class_name} (conf={conf:.2f})")

        return food_objects, filtered_containers


# ==========================================
# 🧠 DINOv2 분류기 — 커스텀 학습 모델 적용
# ==========================================
class DINOv2FoodClassifierModel(nn.Module):
    def __init__(self, num_classes, backbone_name, feature_dim):
        super().__init__()
        self.backbone = AutoModel.from_pretrained(backbone_name)
        for param in self.backbone.parameters():
            param.requires_grad = False
        self.classifier = nn.Sequential(
            nn.Linear(feature_dim, 256),
            nn.LayerNorm(256),
            nn.GELU(),
            nn.Dropout(0.3),
            nn.Linear(256, num_classes)
        )

    def forward(self, x):
        with torch.no_grad():
            outputs = self.backbone(x)
            features = outputs.last_hidden_state[:, 0]
        logits = self.classifier(features)
        return logits


class DINOv2FoodClassifier:
    CONF_THRESHOLD = 0.80

    def __init__(self, model_path="./dinov2_food_classifier.pth"):
        print(f" DINOv2 Classifier Loading... [Device: {device}]")

        checkpoint = torch.load(model_path, map_location=device)
        self.class_names = checkpoint["class_names"]

        self.model = DINOv2FoodClassifierModel(
            num_classes=len(self.class_names),
            backbone_name=checkpoint["backbone_name"],
            feature_dim=checkpoint["feature_dim"]
        ).to(device)

        self.model.classifier.load_state_dict(checkpoint["classifier_state_dict"])
        self.model.eval()

        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            ),
        ])
        print(f" DINOv2 Classifier Ready (Classes: {self.class_names})")

    def classify(self, cropped_img):
        if cropped_img is None or cropped_img.size == 0:
            return "알 수 없는 음식"

        img_rgb = cv2.cvtColor(cropped_img, cv2.COLOR_BGR2RGB)
        pil_img = Image.fromarray(img_rgb)
        input_tensor = self.transform(pil_img).unsqueeze(0).to(device)

        with torch.no_grad():
            logits = self.model(input_tensor)
            probs = torch.softmax(logits, dim=-1)
            max_prob, predicted_idx = torch.max(probs, dim=-1)

            if max_prob.item() < self.CONF_THRESHOLD:
                return "알 수 없는 음식"

            pred_class_name = self.class_names[predicted_idx.item()]

        return pred_class_name


# ==========================================
# 📐 부피 계산기 — [💡 ARKit 실측 두께 정밀 융합 + Fallback]
# ==========================================
class FoodVolumeCalculator:
    FOOD_PRIORS = {
        # === 단일 식재료 ===
        "방울토마토": {
            "strategy": "count_sphere",
            "diameter_cm": 2.5,
            "density": 0.98,
            "kcal_per_100g": 25.0,
            "default_weight_g": 50.0,
            "shape": "볼록형",
        },
        "삶은계란": {
            "strategy": "count_ellipsoid",
            # 💡 [수정] 껍질 깐 삶은계란 1개 ≈ 54g 에 맞춤.
            #    이전 값(4.5×4.0×4.0cm)은 1개가 38.8g 으로 계산돼 실제 55g 계란보다 29% 가벼웠음.
            "axes_cm": (5.4, 4.3, 4.3),
            # 💡 [수정] 위에서 본 계란 1개의 면적(누워 있을 때 π×2.7×2.15 ≈ 18.2cm²).
            #    이전 값 14.0 은 실제보다 작아서, 면적 21.2cm² 가 나오면 1.51 → 반올림으로 "2개"로 세었음.
            "expected_area_cm2": 18.0,
            "density": 1.03,
            "kcal_per_100g": 145.0,
            "default_weight_g": 50.0,
            "shape": "볼록형",
        },
        "닭가슴살": {
            "strategy": "ar_thickness_integration",
            "typical_thickness_cm": 3.5,  # 💡 서버 제공 기본 두께 추가
            "density": 1.05,
            "kcal_per_100g": 165.0,
            "default_weight_g": 100.0,
            "shape": "볼록형",
        },
        "고구마": {
            "strategy": "ar_thickness_integration",
            "typical_thickness_cm": 4.5,  # 가장 두꺼운 부분 기준 (자로 잰 실측값)
            # 💡 [신규] 형상 계수 0.67 — 실측 역산으로 도출.
            # 18cm / 최대두께 4.5cm / 실제 191g 개체에서 면적 61.1cm² 측정 →
            # 필요 부피 183.7cm³ ÷ (61.1 × 4.5) = 0.67
            # 단면이 둥근 데다 양 끝이 크게 가늘어져(평균폭 3.4cm vs 최대폭 4.5cm)
            # 원통 가정(π/4=0.785)보다 더 낮은 계수가 필요함.
            "shape_factor": 0.67,
            # 💡 AR 깊이 실측은 신뢰도가 낮아 사용하지 않음.
            # 단일 카테고리를 두어 항상 typical_thickness_cm(최대두께)를 쓰도록 강제한다.
            # (크기별 세분화는 다른 크기 개체 실측 데이터 확보 후 진행)
            "size_categories": [
                (None, "표준", 4.5),
            ],
            "density": 1.04,
            "kcal_per_100g": 128.0,
            "default_weight_g": 130.0,
            "shape": "볼록형",
        },
        "바나나": {
            "strategy": "ar_thickness_integration",
            "typical_thickness_cm": 3.0,  # 💡 숟가락 자체가 없어 스케일을 못 구한 경우의 최종 fallback
            # 💡 [신규] AR 깊이 실측은 신뢰도가 낮아 폐기하고, 숟가락 스케일로 측정한
            # 실제 길이(cm)를 기준으로 소/보통/대 크기를 판별해 표준 두께를 적용.
            # 형식: (해당 카테고리의 상한 길이 cm, 카테고리명, 표준 두께 cm) / 마지막 항목은 상한 없음(None)
            # 💡 실측 검증 완료 (2.4 / 2.8 / 3.2)
            # - 15.3cm 개체 -> 2.8cm 적용, 오차 작음
            # - 16.0cm 개체 -> 2.8cm 적용, 오차 5~8%
            # - 21.7cm 개체 -> 3.2cm 적용, 오차 5~10g
            # ※ 여기서의 두께는 "단면 최대 두께"가 아니라 전체 면적에 균일하게 곱해지는
            #   평균적 유효 두께임. 실물 중앙부를 자로 재면 3.5cm가 나오는 개체도 있으나,
            #   양 끝이 얇아지므로 그 값을 그대로 넣으면 무게가 과대추정된다.
            # ※ 길이와 두께는 비례하지 않음 (21.7cm 개체가 16cm 개체보다 얇았음).
            #   따라서 길이 구간은 두께를 직접 예측하는 것이 아니라 통계적 대표값을 고르는 용도.
            "size_categories": [
                (15.0, "소형", 2.4),
                (20.0, "보통", 2.8),
                (None, "대형", 3.2),
            ],
            # 💡 형상 계수 π/4 ≈ 0.785 (단면을 원으로 가정한 원통형 보정)
            "shape_factor": 0.785,
            "density": 0.95,
            "kcal_per_100g": 77.0,
            # 💡 [추가] 가식부 비율: 껍질째 촬영/추정한 무게 중 실제로 먹는 과육의 비율.
            # 면적·두께·부피·무게는 모두 껍질 포함 기준이지만,
            # kcal_per_100g(77)은 껍질 벗긴 과육 기준 값이므로 칼로리 계산 시에만 이 비율을 적용한다.
            "edible_ratio": 0.65,
            "default_weight_g": 120.0,
            "shape": "볼록형",
        },
        # === 복합 음식 ===
        "닭가슴살샐러드": {
            "strategy": "menu_based",
            "base_weight_g": 250.0,
            "base_kcal": 300.0,
            "shape": "오목형",
        },
        "포케": {
            "strategy": "menu_based",
            "base_weight_g": 350.0,
            "base_kcal": 500.0,
            "shape": "오목형",
        },
        "그릭요거트": {
            "strategy": "menu_based",
            "base_weight_g": 200.0,
            "base_kcal": 250.0,
            "shape": "오목형",
        },
        "샌드위치": {
            "strategy": "menu_based",
            "base_weight_g": 200.0,
            "base_kcal": 350.0,
            "shape": "볼록형",
        },
    }

    # 💡 [신규] 탄수화물·단백질·지방 기준표 (g)
    # - 단일 식재료: 가식부 100g당 (탄수화물, 단백질, 지방) — kcal_per_100g과 같은 기준
    # - 복합 음식: 1인분당 (탄수화물, 단백질, 지방) — base_kcal과 같은 기준
    # ※ 일반적인 영양성분 자료 기준의 근사값이므로 식약처/USDA 값과 대조해 확정할 것
    MACROS_PER_100G = {
        "방울토마토": (4.8, 0.9, 0.2),
        "삶은계란": (1.0, 12.5, 10.0),
        "닭가슴살": (0.0, 31.0, 3.6),
        "고구마": (30.0, 1.7, 0.1),
        "바나나": (18.0, 0.8, 0.2),
    }
    MENU_MACROS = {
        "닭가슴살샐러드": (15.0, 30.0, 13.0),
        "포케": (62.0, 24.0, 17.0),
        "그릭요거트": (28.0, 16.0, 8.0),
        "샌드위치": (40.0, 16.0, 14.0),
    }

    @classmethod
    def _macros(cls, food_name, edible_g=None):
        """탄수화물/단백질/지방(g) 계산.
        복합 음식은 1인분 기준값, 단일 식재료는 가식부 무게(edible_g) 기준으로 환산.
        기준표에 없으면 빈 dict를 돌려줘 응답에서 해당 키가 빠지게 함."""
        if food_name in cls.MENU_MACROS:
            c, p, f = cls.MENU_MACROS[food_name]
            return {"carbs_g": c, "protein_g": p, "fat_g": f}
        per100 = cls.MACROS_PER_100G.get(food_name)
        if per100 is None or edible_g is None:
            return {}
        c, p, f = per100
        return {
            "carbs_g": round(c * edible_g / 100.0, 1),
            "protein_g": round(p * edible_g / 100.0, 1),
            "fat_g": round(f * edible_g / 100.0, 1),
        }

    @staticmethod
    def _estimate_length_cm(mask, scale_factor_mm_per_px):
        """마스크의 최소 외접 회전 사각형(minAreaRect)에서 긴 변을 실제 길이(cm)로 환산.
        축이 기울어져 있어도(바나나가 화면에서 대각선으로 놓여도) 정확히 측정하기 위해
        축 정렬 bbox 대신 회전 사각형을 사용함."""
        mask_uint8 = (mask == 1).astype(np.uint8) * 255
        contours, _ = cv2.findContours(mask_uint8, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if not contours:
            return 0.0
        largest_contour = max(contours, key=cv2.contourArea)
        (_, (w_px, h_px), _) = cv2.minAreaRect(largest_contour)
        length_px = max(w_px, h_px)
        length_mm = length_px * scale_factor_mm_per_px
        return length_mm / 10.0  # mm -> cm

    @staticmethod
    def _resolve_size_category(length_cm, size_categories):
        """size_categories: [(상한길이cm 또는 None, 카테고리명, 표준두께cm), ...] 오름차순.
        상한이 None인 항목은 그 이상 길이를 모두 흡수하는 마지막 카테고리."""
        for upper_bound, label, thickness_cm in size_categories:
            if upper_bound is None or length_cm < upper_bound:
                return label, thickness_cm
        # 안전망: 정의된 카테고리가 하나도 안 맞으면 마지막 카테고리 사용
        last_label, last_thickness = size_categories[-1][1], size_categories[-1][2]
        return last_label, last_thickness

    @classmethod
    def calculate(cls, food_name, mask, scale_factor_mm_per_px, ar_thickness_cm):
        prior = cls.FOOD_PRIORS.get(food_name)
        if prior is None:
            return None

        strategy = prior["strategy"]

        # === 복합 음식: 숟가락 없어도 1인분 기준값 반환 ===
        if strategy == "menu_based":
            return {
                "weight_g": round(prior["base_weight_g"], 1),
                "calories_kcal": round(prior["base_kcal"], 1),
                "shape_type": prior["shape"],
                "debug": f"메뉴기반 | 1인분 기준 {prior['base_kcal']}kcal",
                **cls._macros(food_name),
            }

        # === 단일 식재료 + 숟가락 없음: 기본 1인분 칼로리 반환 ===
        if scale_factor_mm_per_px is None:
            default_w = prior["default_weight_g"]
            # 💡 [수정] 기본값 경로도 동일하게 가식부 기준으로 칼로리 환산
            default_edible = default_w * prior.get("edible_ratio", 1.0)
            default_cal = round((default_edible / 100.0) * prior["kcal_per_100g"], 1)
            return {
                "weight_g": default_w,
                "calories_kcal": default_cal,
                "shape_type": prior["shape"],
                "debug": f"기본값 | {default_w}g 기준 {default_cal}kcal",
                "needs_spoon": True,
                **cls._macros(food_name, default_edible),
            }

        # === 단일 식재료 + 숟가락 있음: 정밀 무게 추정 ===
        mask_pixel_count = int(np.sum(mask == 1))
        if mask_pixel_count == 0:
            return None

        pixel_area_mm2 = scale_factor_mm_per_px ** 2
        mask_area_cm2 = (mask_pixel_count * pixel_area_mm2) / 100.0

        if strategy == "count_sphere":
            d_cm = prior["diameter_cm"]
            single_area_cm2 = np.pi * (d_cm / 2.0) ** 2
            estimated_count = max(1, round(mask_area_cm2 / single_area_cm2))
            single_volume_cm3 = (4.0 / 3.0) * np.pi * (d_cm / 2.0) ** 3
            volume_cm3 = single_volume_cm3 * estimated_count
            debug = f"구체 개수 정산={estimated_count}개, 면적={mask_area_cm2:.1f}cm²"

        elif strategy == "count_ellipsoid":
            a, b, c = prior["axes_cm"]
            ra, rb, rc = a / 2.0, b / 2.0, c / 2.0
            expected_area = prior["expected_area_cm2"]
            # 💡 [수정] 반올림(1.5 이상이면 2개) 대신, 비율이 1.7 이상일 때만 2개로 셈.
            #    그림자·물기로 면적이 조금 크게 잡혀도 계란 1개를 2개로 세지 않게 함. (2개가 붙어 있으면 비율 ≈ 2.0)
            estimated_count = max(1, int(mask_area_cm2 / expected_area + 0.3))
            single_volume_cm3 = (4.0 / 3.0) * np.pi * ra * rb * rc
            volume_cm3 = single_volume_cm3 * estimated_count
            debug = f"타원체 개수 정산={estimated_count}개, 면적={mask_area_cm2:.1f}cm²"

        elif strategy == "ar_thickness_integration":
            # 💡 [수정] 형상 계수를 음식명 하드코딩이 아닌 prior 속성에서 읽어온다.
            # 1.0 = 각기둥(면적×두께 그대로), 0.785 = 원통형, 그 이하 = 양 끝이 가늘어지는 형태.
            # 값이 없는 식재료는 기존과 동일하게 1.0으로 동작.
            shape_factor = prior.get("shape_factor", 1.0)
            debug_msg = f"형상계수 {shape_factor}"

            # 💡 [신규] 크기 카테고리(소/보통/대) 기반 표준 두께 우선 적용
            # 이 분기에 도달했다는 건 위쪽 early-return에서 이미 걸러졌으므로
            # scale_factor_mm_per_px는 항상 존재함 (숟가락 미검출 시엔 여기 못 옴)
            size_categories = prior.get("size_categories")
            if size_categories:
                length_cm = cls._estimate_length_cm(mask, scale_factor_mm_per_px)
                size_label, effective_thickness = cls._resolve_size_category(length_cm, size_categories)
                thickness_source = f"크기표준({size_label}, 실측길이 {length_cm:.1f}cm)"
            # 💡 [기존 로직 보존] size_categories가 없는 식재료(닭가슴살, 고구마)는 그대로 AR 실측/서버기본 사용
            elif ar_thickness_cm > 0.0:
                effective_thickness = ar_thickness_cm
                thickness_source = "AR실측"
            else:
                effective_thickness = prior.get("typical_thickness_cm", 3.0)
                thickness_source = "서버기본"

            # 부피 = 정확한 픽셀 실측 면적 x (크기표준 or 실측 or 기본) 두께 x 형상 계수
            volume_cm3 = mask_area_cm2 * effective_thickness * shape_factor
            debug = f"면적={mask_area_cm2:.1f}cm², {thickness_source}두께={effective_thickness:.1f}cm ({debug_msg})"

        else:
            return None

        weight_g = volume_cm3 * prior["density"]
        weight_g = float(np.clip(weight_g, 5.0, 1500.0))
        weight_g = round(weight_g, 1)

        # 💡 [수정] 칼로리는 실제로 먹는 부분(가식부) 기준으로 계산.
        # weight_g는 껍질 포함 무게이므로 그대로 두고(사용자가 저울로 잰 값과 비교 가능),
        # 칼로리 환산 시에만 edible_ratio를 곱한다. 껍질이 없는 식재료는 기본값 1.0.
        edible_g = weight_g * prior.get("edible_ratio", 1.0)
        calories = round((edible_g / 100.0) * prior["kcal_per_100g"], 1)

        return {
            "weight_g": weight_g,
            "calories_kcal": calories,
            "shape_type": prior["shape"],
            "debug": debug,
            **cls._macros(food_name, edible_g),
        }


# ==========================================
# 서버 엔진 초기화 (MiDaS 제거)
# ==========================================
spoon_detector = SpoonDetector()
food_segmenter = FoodVsBowlSegmenter()
classifier = DINOv2FoodClassifier(model_path="./dinov2_food_classifier.pth")


def macro_fields(result):
    """계산 결과에서 탄단지 키만 골라 응답용 float로 변환 (없으면 빈 dict)"""
    return {k: float(result[k]) for k in ("carbs_g", "protein_g", "fat_g") if k in result}


# ==========================================
# 🌐 FastAPI 엔드포인트 (thickness 파라미터 수신)
# ==========================================
@app.post("/analyze-food/")
async def analyze_food(
        file: UploadFile = File(...),
        thickness: float = Form(0.0)  # 💡 기본값을 0.0으로 변경 (파라미터 누락/실패 시 Fallback 발동)
):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    # ---------- 1. 숟가락 감지 → 스케일 획득 ----------
    spoon = spoon_detector.detect(img)
    spoon_bbox = spoon["bbox"] if spoon else None
    scale_factor = spoon_detector.compute_scale_factor(spoon["length_px"]) if spoon else None

    if scale_factor is not None:
        print(f"\n🎯 [스케일 획득] 1픽셀 = {scale_factor:.4f} mm (숟가락 기준)")
    else:
        print(f"\n⚠️ [스케일 없음] 숟가락 미감지 → 복합 음식은 분류 가능, 단일 식재료는 기본 칼로리 제공")

    # ---------- 2. YOLOE로 음식만 분할 (그릇 자동 필터링) ----------
    detected_objects, filtered_containers = food_segmenter.detect(img)
    print(f"\n[엑스레이] YOLOE가 분할한 음식 덩어리: {len(detected_objects)}개")

    response_results = []

    # ---------- 3. 음식 객체 순회 ----------
    for i, obj in enumerate(detected_objects):
        bbox = obj["bbox"]

        # 숟가락과 겹치는 영역은 음식이 아님
        if spoon_bbox:
            cx, cy = (bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2
            if (spoon_bbox[0] <= cx <= spoon_bbox[2]
                    and spoon_bbox[1] <= cy <= spoon_bbox[3]):
                print(f" ⏭️ [조각 {i}] 숟가락과 중첩 -> 스킵")
                continue

        x_min, y_min, x_max, y_max = bbox
        h_img, w_img = img.shape[:2]
        img_area = h_img * w_img
        box_area = (x_max - x_min) * (y_max - y_min)
        area_ratio = box_area / img_area

        # 기하학적 필터링
        if area_ratio > 0.7:
            print(f" ⏭️ [조각 {i}] 화면의 70% 초과 -> 스킵 (배경 오인식 의심)")
            continue
        if area_ratio < 0.01:
            print(f" ⏭️ [조각 {i}] 화면의 1% 미만 -> 스킵 (먼지/그림자)")
            continue

        x_min, y_min = max(0, x_min), max(0, y_min)
        x_max, y_max = min(w_img, x_max), min(h_img, y_max)

        # 분류기로 음식 종류 판별
        cropped_img = img[y_min:y_max, x_min:x_max]
        food_name = classifier.classify(cropped_img)

        if food_name == "알 수 없는 음식":
            print(f" ❌ [조각 {i}] 면적: {area_ratio * 100:.2f}% -> 확신도 부족")
            continue

        print(f" ✅ [조각 {i}] 면적: {area_ratio * 100:.2f}% -> {food_name}")

        # ARKit 실측치를 반영한 정밀 계산 가동
        result = FoodVolumeCalculator.calculate(
            food_name=food_name,
            mask=obj["mask"],
            scale_factor_mm_per_px=scale_factor,
            ar_thickness_cm=thickness
        )

        if result is None:
            print(f"   ⚠️ {food_name}의 prior 정보가 없습니다.")
            continue

        print(f"   📊 [최종] {food_name} -> {result['weight_g']}g, "
              f"{result['calories_kcal']}kcal | {result['debug']}")

        response_results.append({
            "food_name": str(food_name),
            "weight_g": float(result["weight_g"]),
            "calories_kcal": float(result["calories_kcal"]),
            "shape_type": result["shape_type"],
            **macro_fields(result),
            **({"message": "숟가락을 놓으면 더 정확한 무게/칼로리 추정이 가능합니다"}
               if result.get("needs_spoon") else {}),
        })

    # === 그릇 백업 복구 로직 보존 ===
    if len(response_results) == 0 and len(filtered_containers) > 0:
        largest = max(filtered_containers,
                      key=lambda c: (c["bbox"][2] - c["bbox"][0]) * (c["bbox"][3] - c["bbox"][1]))
        print(f"\n🔄 [그릇 복구] 결과 0개 → 필터링된 {largest['raw_class']}을 음식 후보로 복구")
        bx = largest["bbox"]
        bx_min, by_min = max(0, bx[0]), max(0, bx[1])
        bx_max, by_max = min(img.shape[1], bx[2]), min(img.shape[0], bx[3])
        cropped = img[by_min:by_max, bx_min:bx_max]
        food_name = classifier.classify(cropped)
        if food_name != "알 수 없는 음식":
            result = FoodVolumeCalculator.calculate(
                food_name=food_name, mask=largest["mask"],
                scale_factor_mm_per_px=None, ar_thickness_cm=thickness
            )
            if result is not None:
                print(f"   📊 [복구 성공] {food_name} -> {result['weight_g']}g, {result['calories_kcal']}kcal")
                entry = {
                    "food_name": str(food_name),
                    "weight_g": float(result["weight_g"]),
                    "calories_kcal": float(result["calories_kcal"]),
                    "shape_type": result["shape_type"],
                }
                entry.update(macro_fields(result))
                if result.get("needs_spoon"):
                    entry["message"] = "숟가락을 놓으면 더 정확한 무게/칼로리 추정이 가능합니다"
                response_results.append(entry)

    # === 복합 음식(menu_based) 중복 제거 로직 보존 ===
    menu_based_names = {name for name, prior in FoodVolumeCalculator.FOOD_PRIORS.items()
                        if prior.get("strategy") == "menu_based"}
    seen_menu = set()
    deduplicated = []
    for entry in response_results:
        name = entry["food_name"]
        if name in menu_based_names:
            if name in seen_menu:
                print(f"   🔄 [중복 제거] {name} 중복 → 1개만 유지")
                continue
            seen_menu.add(name)
        deduplicated.append(entry)
    response_results = deduplicated

    return {
        "status": "success",
        "scale_mm_per_px": round(scale_factor, 4) if scale_factor else None,
        "spoon_length_px": round(spoon["length_px"], 1) if spoon else None,   # 스케일 점검용
        "spoon_detected": scale_factor is not None,
        "results": response_results
    }


if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)