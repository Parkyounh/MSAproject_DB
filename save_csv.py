import pandas as pd
import mysql.connector
from mysql.connector import Error

# 1. 환경 설정 및 파일 경로 정의
# ----------------------------------------------------------------------
DB_CONFIG = {
    'host': 'localhost',      
    'database': 'msaproject', 
    'user': 'root',      
    'password': '1234', 
    'port':3305
}

# 로드할 CSV 파일 목록과 해당 테이블명 및 컬럼 매핑 정보
FILES_TO_LOAD = [
    {
        'file_name': '재고.csv',
        'table_name': 'material_master',
        'dtype_map': {'stock_qty': float}, 
        'col_map': {
            '재료': 'ingredient_name',
            '단위': 'base_unit',
            'stock_qty (재고량)': 'stock_qty'
        }
    },
    {
        'file_name': '기본 상품 정보.csv',
        'table_name': 'menu',
        'dtype_map': {'기본 판매가': int}, 
        'col_map': {
            '메뉴 코드': 'menu_code',
            '메뉴명': 'menu_name',
            '카테고리': 'category',
            '기본 판매가': 'base_price',
            '기본 용량': 'base_volume',
            '알레르기 정보': 'allergy_info',
            '설명': 'description',
            '제작 시간':'create_time'
        }
    },
    {
        'file_name': '옵션.csv',
        'table_name': 'option_master',
        'dtype_map': {'default_price': int, 'quantity': float}, 
        'col_map': {
            # 🚨 수정: CSV 스니펫에 따라 'optionn_group_name'으로 수정
            'optionn_group_name': 'option_group_name',
            'option_name': 'option_name',
            'default_price': 'default_price',
            'changing_material': 'changing_material',
            'quantity': 'quantity',
            'unit': 'unit',
            'process_method': 'process_method'
        }
    },
    {
        'file_name': '영양 성분 정보.csv',
        'table_name': 'nutrition',
        'dtype_map': {
            '칼로리(kcal)': float, '나트륨(mg)': float, '탄수화물(g)': float, 
            '당류(g)': float, '단백질(g)': float, '지방(g)': float, 
            '포화지방(g)': float, '카페인(mg)': float
        },
        'col_map': {
            '메뉴 코드': 'menu_code',
            '칼로리(kcal)': 'calories',
            '나트륨(mg)': 'sodium',
            '탄수화물(g)': 'carbs',
            '당류(g)': 'sugars',
            '단백질(g)': 'protein',
            '지방(g)': 'fat',
            '포화지방(g)': 'saturated_fat',
            '카페인(mg)': 'caffeine'
        }
    },
    {
        'file_name': '레시피.csv',
        'table_name': 'recipe',
        'dtype_map': {'소요량': float}, 
        'col_map': {
            '메뉴코드': 'menu_code',
            '재료명': 'ingredient_name',
            '재료구분': 'ingredient_category',
            '소요량': 'required_quantity',
            '단위': 'unit'
        }
    }
]

# 2. 데이터베이스 연결 함수 (동일)
# ----------------------------------------------------------------------
def connect_db():
    """MySQL 데이터베이스에 연결"""
    conn = None
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        print("✅ MySQL 연결 성공!")
        return conn
    except Error as e:
        print(f"❌ MySQL 연결 실패: {e}")
        return None

# 3. 데이터 적재 함수 (핵심 로직 수정됨)
# ----------------------------------------------------------------------
def load_data_to_db(conn, file_info):
    """지정된 CSV 파일을 읽어 MySQL 테이블에 데이터를 적재합니다."""
    
    file_name = file_info['file_name']
    table_name = file_info['table_name']
    col_map = file_info['col_map']
    dtype_map = file_info['dtype_map']
    
    print(f"\n--- 📂 {file_name} -> 📊 {table_name} 적재 시작 ---")
    
    try:
        # 🌟 인코딩 수정: 'cp949' 추가 (이전 오류 해결)
        df = pd.read_csv(file_name, dtype=dtype_map, encoding='cp949')
        
        # 컬럼명 변경 (CSV 컬럼명 -> DB 컬럼명)
        df.rename(columns=col_map, inplace=True)
        
        # 매핑된 DB 컬럼만 선택하고, 결측값(NaN)을 DB에 NULL로 들어갈 수 있도록 None으로 변환
        db_columns = list(col_map.values())
        df = df[db_columns].where(pd.notnull(df), None)
        
        # INSERT 쿼리 생성
        # 🌟 쿼리 수정: 컬럼명에 백틱(`)을 추가하여 안정성 확보
        columns_str = ", ".join([f"`{col}`" for col in db_columns])
        placeholders = ", ".join(["%s"] * len(db_columns))
        insert_query = f"INSERT INTO `{table_name}` ({columns_str}) VALUES ({placeholders})"
        
        # 데이터프레임의 행(Row)을 튜플 리스트로 변환
        data_to_insert = [tuple(row) for row in df.values]
        
        cursor = conn.cursor()
        
        # Bulk Insert 실행
        cursor.executemany(insert_query, data_to_insert)
        conn.commit()
        
        print(f"🎉 {table_name} 테이블에 {cursor.rowcount}개의 레코드 적재 완료.")
        
    except FileNotFoundError:
        print(f"❌ 오류: 파일을 찾을 수 없습니다: {file_name}")
    except Error as e:
        print(f"❌ DB 적재 중 오류 발생 ({table_name}): {e}")
        conn.rollback()
    except Exception as e:
        print(f"❌ 예상치 못한 오류 발생 ({file_name}): {e}")

# 4. 메인 실행 로직 (동일)
# ----------------------------------------------------------------------
if __name__ == "__main__":
    conn = connect_db()
    
    if conn:
        # Foreign Key 제약 조건 순서에 따라 데이터 적재 실행
        # material_master, menu는 부모 테이블이므로 먼저 로드
        load_data_to_db(conn, FILES_TO_LOAD[0]) # material_master
        load_data_to_db(conn, FILES_TO_LOAD[1]) # menu
        load_data_to_db(conn, FILES_TO_LOAD[2]) # option_master
        
        # nutrition, recipe_detail은 부모 테이블이 로드된 후 로드
        load_data_to_db(conn, FILES_TO_LOAD[3]) # nutrition
        load_data_to_db(conn, FILES_TO_LOAD[4]) # recipe_detail
        
        conn.close()
        print("\n--- 🚀 데이터 적재 프로세스 완료 ---")