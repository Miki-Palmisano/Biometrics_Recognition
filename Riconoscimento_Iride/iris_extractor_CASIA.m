clear all; close all; clc;
folder = "001";
imageN = "01";
%% Importa immagine
image_path = './casia-iris-syn/'+folder+'/S6'+folder+'S'+imageN+'.jpg';
AIris = imread(image_path);
imshow(AIris);
title('Immagine originale');

%% Pre-elaborazione
% Riduzione del rumore con filtro mediano
AIris_filtered = medfilt2(AIris, [17 17]); % definisco una finestra quadrata
figure;
imshow(AIris_filtered);
title('Immagine filtrata');

%% Rilevamento dei bordi
AIris_edges = edge(AIris_filtered, "canny", 0.13); % Regola soglia di Canny
figure;
imshow(AIris_edges);
title('Contorni rilevati (Canny)');

%% Rilevamento dell'iride
min_iride = 90;
max_iride = 130;

[centers_iride, radius_iride] = imfindcircles(AIris_edges, [min_iride max_iride], ...
    "Sensitivity", 0.98, "EdgeThreshold", 0.5);
% Sensitivity indica la sensibilità della ricerca, ovvero cerchera anche
% cerchi deboli
% EdgeThreshold indica la soglia per considerare se un pixel fa parte del
% bordo del cerchio


hold on;
if isempty(radius_iride)
    error("Iride non rilevata! Regola i parametri di imfindcircles.");
else
    figure;
    imshow(AIris);
    viscircles(centers_iride, radius_iride, 'Color', 'b');
    title('Iride rilevata');
end

%% Rilevamento della pupilla
min_pupils = 30;
max_pupils = 70;

[centers_pupils, radius_pupils] = imfindcircles(AIris_edges, [min_pupils max_pupils], ...
    "Sensitivity", 0.90, "EdgeThreshold", 0.3);
% Sensitivity indica la sensibilità della ricerca, ovvero cerchera anche
% cerchi deboli
% EdgeThreshold indica la soglia per considerare se un pixel fa parte del
% bordo del cerchio


if isempty(radius_pupils)
    error("Pupilla non rilevata! Regola i parametri di imfindcircles.");
else
    % disegno cerchi sull'immagine
    viscircles(centers_pupils, radius_pupils, 'Color', 'r');
end

%% Creazione della maschera per l'iride
[col, row] = size(AIris);
[xx, yy] = meshgrid(1:row, 1:col);

% Maschera per l'iride e la pupilla
mask_iride = (xx - centers_iride(1)).^2 + (yy - centers_iride(2)).^2 <= radius_iride^2;
mask_pupilla = (xx - centers_pupils(1)).^2 + (yy - centers_pupils(2)).^2 <= radius_pupils^2;
mask = mask_iride & ~mask_pupilla;

% Applicazione della maschera
AIris_masked = AIris;
AIris_masked(~mask) = 0;

figure;
imshow(AIris_masked);
title('Iride mascherata');

%% Rilevamento delle palpebre
AIris_p = medfilt2(AIris, [27 27]);
AIris_edges = edge(AIris_p, "sobel", "horizontal");
AIris_edges(~mask) = 0;
imshow(AIris_edges);

% Trasformata di Hough per linee
[Hough_space, Theta, Rho] = hough(AIris_edges);

% Trova picchi di Hough, ovver le linee più evidenti
peaks = houghpeaks(Hough_space, 20, "Threshold", ceil(0.3 * max(Hough_space(:))));
% Estrae le linee corrispondenti ai picchi
lines = houghlines(AIris_edges, Theta, Rho, peaks, "FillGap", 30, "MinLength", 50);

% Rimuovi le regioni coperte dalle palpebre
for k = 1:length(lines)
    point1 = lines(k).point1;
    point2 = lines(k).point2;

    % Calcola pendenza della linea
    m = (point2(2) - point1(2)) / (point2(1) - point1(1));
    b = point1(2) - m * point1(1);

    % Crea maschera per palpebra superiore e inferiore
    if mean([point1(2), point2(2)]) < centers_pupils(2)
        y_retta = m * xx + b;
        mask(yy < y_retta) = 0;
    elseif mean([point1(2), point2(2)]) > centers_pupils(2)
        y_retta = m * xx + b;
        mask(yy > y_retta) = 0;
    end
end

% Applica la maschera finale
AIris_no_palpebra = AIris;
AIris_no_palpebra(~mask) = 0;

figure;
imshow(AIris_no_palpebra);
title('Iride senza pupilla e palpebre');

%% Conversione in coordinate polari
theta_step = 360;
r_step = 100;

theta = linspace(0, 2 * pi, theta_step);
r = linspace(radius_pupils, radius_iride, r_step);

AIris_cord = zeros(r_step, theta_step);

for i = 1:r_step
    for j = 1:theta_step
        x = round(centers_iride(1) + r(i) * cos(theta(j)));
        y = round(centers_iride(2) + r(i) * sin(theta(j)));

        if x > 0 && x <= row && y > 0 && y <= col
            AIris_cord(i, j) = AIris_no_palpebra(y, x);
        else
            AIris_cord(i, j) = NaN;
        end
    end
end

figure;
imshow(uint8(AIris_cord));
title('Iride trasformata in coordinate polari');

if ~exist("./iris-converted/"+folder, 'dir')
    mkdir("./iris-converted/"+folder)
    fprintf('Cartella creata con successo.');
end
imwrite(uint8(AIris_cord), './iris-converted/'+folder+'/'+imageN+'.jpg');