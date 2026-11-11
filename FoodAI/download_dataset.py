from icrawler.builtin import BingImageCrawler
import os

diet_classes = {
    "banana": "바나나",
    "sweet_potato": "삶은 고구마",
    "chicken_breast": "닭가슴살",
    "cherry_tomato": "방울토마토",
    "boiled_egg": "삶은 달걀"
}

# 📌 핵심 수정: BingImageCrawler 생성 시 설정을 주입합니다.
for class_name, keyword in diet_classes.items():
    save_dir = os.path.join("./my_diet_dataset/train", class_name)
    os.makedirs(save_dir, exist_ok=True)

    bing_crawler = BingImageCrawler(
        feeder_threads=1,
        parser_threads=1,
        downloader_threads=4,
        storage={'root_dir': save_dir}
    )

    # 📌 extra_params 대신, 크롤링 시 검색 설정으로 직접 주입합니다.
    # icrawler의 Bing 엔진은 이렇게 한국어 마켓 설정이 들어갑니다.
    bing_crawler.crawl(
        keyword=keyword,
        max_num=150,
        filters={'mkt': 'ko-KR'}  # 👈 이게 빙 크롤러의 정확한 필터 문법입니다!
    )