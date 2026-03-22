#!/usr/bin/env python3
"""
Скрипт фильтрации подозрительных событий из логов minikube
"""

import re
import json

def main():
    suspicious_events = []
    log_files = [
        '/Users/jo/minikube-full.log',
        '/Users/jo/audit-events.log',
        '/Users/jo/audit.log'
    ]
    
    for log_file in log_files:
        try:
            with open(log_file, 'r') as f:
                for line in f:
                    line_lower = line.lower()
                    
                    # 1. Доступ к секретам
                    if 'secret' in line_lower and 'forbidden' in line_lower:
                        suspicious_events.append({
                            'type': 'SECRET_ACCESS_FORBIDDEN',
                            'source': log_file,
                            'description': 'Попытка доступа к секретам отклонена',
                            'raw': line.strip()[:500]
                        })
                    
                    # 2. Привилегированный под
                    if 'privileged' in line_lower and 'true' in line_lower:
                        suspicious_events.append({
                            'type': 'PRIVILEGED_POD',
                            'source': log_file,
                            'description': 'Создание привилегированного пода',
                            'raw': line.strip()[:500]
                        })
                    
                    # 3. Exec операция
                    if 'exec' in line_lower and ('create' in line_lower or 'exec' in line_lower):
                        suspicious_events.append({
                            'type': 'EXEC_OPERATION',
                            'source': log_file,
                            'description': 'Выполнение команды в поде',
                            'raw': line.strip()[:500]
                        })
                    
                    # 4. RoleBinding
                    if 'rolebinding' in line_lower and 'cluster-admin' in line_lower:
                        suspicious_events.append({
                            'type': 'RISKY_ROLEBINDING',
                            'source': log_file,
                            'description': 'Создание RoleBinding с cluster-admin',
                            'raw': line.strip()[:500]
                        })
                    
                    # 5. Успешное создание пода
                    if 'pod' in line_lower and 'created' in line_lower:
                        suspicious_events.append({
                            'type': 'POD_CREATED',
                            'source': log_file,
                            'description': 'Создание пода',
                            'raw': line.strip()[:500]
                        })
                        
        except FileNotFoundError:
            continue
    
    # Сохраняем результаты
    with open('/Users/jo/audit-extract.json', 'w') as f:
        json.dump(suspicious_events, f, indent=2, ensure_ascii=False)
    
    print(f"Найдено подозрительных событий: {len(suspicious_events)}")
    
    # Статистика
    types = {}
    for event in suspicious_events:
        t = event.get('type', 'UNKNOWN')
        types[t] = types.get(t, 0) + 1
    
    print("\nСтатистика:")
    for t, count in types.items():
        print(f"  {t}: {count}")

if __name__ == '__main__':
    main()
