% n 개의 추에 대해 첫번째 추의 진동수가 f_min 경우 Pendulum 길이 벡터를 반환합니다.
function length = Pendulum_Length ( n, f_min )
    g = 9.8;
    L = linspace(0,0,n);
    N = linspace(0,0,n);
    F = linspace(0,0,n);
    N(1) = f_min;
    for i=1:n
        N(i) = N(1)+i-1;
        F(i) = N(i)*1/60;
        L(i) = g/(4*(pi^2)*F(i)^2);
    end
    length = L;
    disp(F)
    
end