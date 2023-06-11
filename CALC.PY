for i in range(2, 101):
    i = i / 10
    t = 1 / i / 6
    yuliu = t * 24.5 * pow(10, 6) / 8 / 48
    res = round((1 << 16) - yuliu) - 12
    print(hex(res)[2:].upper(), end="H, 0")
# i = 100
# i = i / 10
# t = 1 / i / 6
# yuliu = t * 24.5 * pow(10, 6) / 8 / 48
# res = round((1 << 16) - yuliu) - 12
# print(hex(res)[2:].upper(), end="H, 0")