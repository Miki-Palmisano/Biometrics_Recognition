clear all; close all; clc;
folder = "050";
imageN = "3";
imageC = "6";
%% Importa immagine
image_path = './iris_images/iris49_56/left/'+folder+'L_'+imageN+'.png';
%converto in grayscale
AIris = rgb2gray(imread(image_path));
imshow(AIris);
title('Immagine originale');

%% Pre-elaborazione
% Riduzione del rumore applicando il filtro mediano
AIris_filtered = medfilt2(AIris, [25 25]); % definisco una finestra quadrata

figure;
imshow(AIris_filtered);
title('Immagine filtrata');

%% Rilevamento dei bordi
% filtro di canny per rilevare i bordi
AIris_edges = edge(AIris_filtered, "canny", 0.05); % Regola soglia di Canny

figure;
imshow(AIris_edges);
title('Contorni rilevati (Canny)');

%% Rilevamento dell'iride
min_iride = 190;
max_iride = 280;

% trasformata di hough per rilevare i cerchi, mi ritorna centro e raggio
[centers_iride, radius_iride] = imfindcircles(AIris_edges, [min_iride max_iride], ...
    "Sensitivity", 0.98, "EdgeThreshold", 0.3);
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
    % disegno cerchi sull'immagine
    viscircles(centers_iride, radius_iride, 'Color', 'b');
    title('Iride rilevata');
end

%% Pre-elaborazione
% Riduzione del rumore
% riapplico un filtro mediano con finestra diversa 
AIris_filtered = medfilt2(AIris, [15 15]); % Filtro mediano

%% Rilevamento dei bordi
AIris_edges = edge(AIris_filtered, "canny", 0.02); % Regola soglia di Canny
%figure;
%imshow(AIris_edges);
%title('Contorni rilevati (Canny)');

%% Rilevamento della pupilla
min_pupils = 50;
max_pupils = 130;

[centers_pupils, radius_pupils] = imfindcircles(AIris_edges, [min_pupils max_pupils], ...
    "Sensitivity", 0.94, "EdgeThreshold", 0.2);
% Sensitivity indica la sensibilità della ricerca, ovvero cercherà anche
% cerchi deboli
% EdgeThreshold indica la soglia per considerare se un pixel fa parte del
% bordo del cerchio

if isempty(radius_pupils)
    error("Pupilla non rilevata! Regola i parametri di imfindcircles.");
else
    viscircles(centers_pupils, radius_pupils, 'Color', 'r');
    title('Iride e pupilla rilevate');
end

hold off;

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
            AIris_cord(i, j) = AIris_masked(y, x);
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
imwrite(uint8(AIris_cord), './iris-converted/'+folder+'/'+imageC+'.jpg');