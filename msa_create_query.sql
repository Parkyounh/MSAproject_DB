create database msaproject;
drop database msaproject;
use msaproject;

CREATE TABLE menu (
    menu_code VARCHAR(10) PRIMARY KEY COMMENT '메뉴 코드',
    menu_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    base_price INT NOT NULL COMMENT '기본 판매가',
    base_volume VARCHAR(50) COMMENT '기본 용량',
    allergy_info VARCHAR(255) COMMENT '알레르기 정보',
    description TEXT COMMENT '설명',
    create_time INT COMMENT '제작 소요 시간 (초 단위)'
);

CREATE TABLE material_master (
    ingredient_id INT AUTO_INCREMENT PRIMARY KEY,
    ingredient_name VARCHAR(100) NOT NULL UNIQUE COMMENT '재료명 (FK 참조 기준)',
    base_unit VARCHAR(10) NOT NULL COMMENT '기본 재고 관리 단위',
    stock_qty DECIMAL(10, 2) DEFAULT 0 COMMENT '현재 재고량'
);


CREATE TABLE option_master (
    option_id INT AUTO_INCREMENT PRIMARY KEY,
    option_group_name VARCHAR(50) NOT NULL COMMENT '옵션 그룹',
    option_name VARCHAR(100) NOT NULL COMMENT '옵션 이름',
    default_price INT NOT NULL COMMENT '옵션 비용',
    from_material VARCHAR(100) NULL COMMENT '기존 재료(삭제되는 재료)',
    to_material   VARCHAR(100) NULL COMMENT '변경 후 재료(추가되는 재료)',
    quantity DECIMAL(8,2) NOT NULL COMMENT '변동 수량',
    unit VARCHAR(10) NOT NULL COMMENT '단위',
    process_method ENUM('추가', '제거', '변경') NOT NULL COMMENT '처리 방식'
);


CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_date DATETIME NOT NULL,
    total_amount INT NOT NULL COMMENT '총 주문 금액',
    customer_id INT COMMENT '고객 테이블의 FK (선택적)',
    status VARCHAR(20) COMMENT '주문 상태'
);

CREATE TABLE nutrition (
    menu_code VARCHAR(10) PRIMARY KEY COMMENT '메뉴 코드 (PK이자 FK)',
    calories DECIMAL(6, 2) COMMENT '칼로리(kcal)',
    sodium DECIMAL(6, 2) COMMENT '나트륨(mg)',
    carbs DECIMAL(6, 2) COMMENT '탄수화물(g)',
    sugars DECIMAL(6, 2) COMMENT '당류(g)',
    protein DECIMAL(6, 2) COMMENT '단백질(g)',
    fat DECIMAL(6, 2) COMMENT '지방(g)',
    saturated_fat DECIMAL(6, 2) COMMENT '포화지방(g)',
    caffeine DECIMAL(6, 2) COMMENT '카페인(mg)',
    
    FOREIGN KEY (menu_code) REFERENCES menu(menu_code)
);


CREATE TABLE recipe (
    recipe_detail_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    menu_code VARCHAR(10) NOT NULL COMMENT '메뉴 코드 (FK)',
    ingredient_name VARCHAR(100) NOT NULL COMMENT '재료명 (FK)',
    ingredient_category VARCHAR(50) COMMENT '재료 구분',
    required_quantity DECIMAL(8, 2) NOT NULL COMMENT '소요량',
    unit VARCHAR(10) NOT NULL COMMENT '단위',

    FOREIGN KEY (menu_code) REFERENCES menu(menu_code),
    FOREIGN KEY (ingredient_name) REFERENCES material_master(ingredient_name)
);

CREATE TABLE order_item (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL COMMENT '주문 테이블의 FK',
    menu_code VARCHAR(10) NOT NULL COMMENT '메뉴 테이블의 FK',
    quantity INT NOT NULL,
    price_at_order INT NOT NULL COMMENT '주문 시점의 메뉴 항목 기본가',
    total_item_price INT NOT NULL COMMENT '옵션 포함 항목 최종 가격',

    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (menu_code) REFERENCES menu(menu_code)
);

CREATE TABLE order_option (
    order_option_id INT AUTO_INCREMENT PRIMARY KEY,
    order_item_id INT NOT NULL COMMENT '주문 상세 테이블의 FK',
    option_id INT NOT NULL COMMENT '옵션 마스터 테이블의 FK',
    option_price_at_order INT NOT NULL COMMENT '주문 시점의 옵션 가격',
    
    FOREIGN KEY (order_item_id) REFERENCES order_item(order_item_id),
    FOREIGN KEY (option_id) REFERENCES option_master(option_id)
);

#-----------------------------------------장바구니------------
-- 장바구니 헤더 테이블 (사용자별 장바구니)
CREATE TABLE cart_header (
    cart_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT COMMENT '고객 테이블의 FK',
    created_at DATETIME NOT NULL COMMENT '장바구니 생성/업데이트 시점'
    -- FOREIGN KEY (customer_id) REFERENCES customer(customer_id) (고객 테이블이 있다면)
);

-- 장바구니 항목 테이블 (담은 메뉴 항목)
CREATE TABLE cart_item (
    cart_item_id INT AUTO_INCREMENT PRIMARY KEY,
    cart_id INT NOT NULL COMMENT '장바구니 헤더의 FK',
    menu_code VARCHAR(10) NOT NULL COMMENT '메뉴 테이블의 FK',
    quantity INT NOT NULL COMMENT '주문 수량',
    unit_price INT NOT NULL COMMENT '장바구니 담을 시점의 메뉴 기본 가격',
    
    FOREIGN KEY (cart_id) REFERENCES cart_header(cart_id),
    FOREIGN KEY (menu_code) REFERENCES menu(menu_code)
);

-- 장바구니 옵션 테이블 (항목별 옵션 정보)
CREATE TABLE cart_option (
    cart_option_id INT AUTO_INCREMENT PRIMARY KEY,
    cart_item_id INT NOT NULL COMMENT '장바구니 항목의 FK',
    option_id INT NOT NULL COMMENT '옵션 마스터의 FK',
    option_price INT NOT NULL COMMENT '장바구니 담을 시점의 옵션 가격',
    
    FOREIGN KEY (cart_item_id) REFERENCES cart_item(cart_item_id),
    FOREIGN KEY (option_id) REFERENCES option_master(option_id)
);