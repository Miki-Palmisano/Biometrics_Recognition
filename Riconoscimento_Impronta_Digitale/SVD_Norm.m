%% clear space
clear all, close all, clc

n_person = 50;
n_finger = 10;
base_path = "./socofing/SOCOFing/Real/";
%% Elaboro la matrice delle impronte

AIfing_matrix = [];

for i = 1: (n_person - 5)

    for j = 1:n_finger
        img_path = base_path + i + "_" + j + ".BMP";

        AIfing = imread(img_path);
        AIfing = double(rgb2gray(AIfing));

        AIfing_matrix = [AIfing_matrix AIfing(:)];

        fprintf("Immagine: " + j + " cartella: " + i + "\n")
    end

end

%% Centro la matrice e applico SVD
mean_AIfing = mean(AIfing_matrix, 2);
AIfing_matrix = AIfing_matrix - (mean_AIfing * ones(1, size(AIfing_matrix, 2)));
[U, S, V] = svd(AIfing_matrix, "econ");

% trovo l'indice che spiega almeno 90% dell'energia
k = find(cumsum(diag(S).^2)/sum(diag(S).^2) > 0.7, 1);

figure;
imagesc(corr(AIfing_matrix));
colorbar;
title('Matrice di correlazione delle impronte');
colormap jet;

%% grafico energia
energia=cumsum(diag(S).^2)/sum(diag(S).^2);
hold on;
plot(1:length(energia),energia, 'LineWidth',2,'Color','g')

% Esempio: evidenziare i punti di interesse
punti = [2 3 13 50 124 295]; % Indici dei punti da evidenziare (puoi modificarli)
valori_punti = energia(punti); % Valori corrispondenti

for t = 1 : 6
    % Aggiungi marker sui punti specifici
    plot(punti(t), valori_punti(t), 'bo', 'MarkerFaceColor', 'b'); % Punti con cerchi blu pieni
    text(punti(t), valori_punti(t), sprintf('%.2f%%', valori_punti(t)), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
end

xlabel('Valori Singolari')
ylabel('Energia Spiegata')

hold off;

%% Visualizzo i primi Eigeniris
%
numEigenIrisToShow = 9; % Numero di autovettori da visualizzare
figure;
for i = 1:numEigenIrisToShow
    eigenIris = reshape(U(:, i), [103 96]); % Reshape in immagine
    subplot(3, 3, i);
    imshow(eigenIris, []);
    title(['Eigeniris #' num2str(i)]);
end
%}

%% Calcolo precisione
%
tic;
TP = 0;
FP = 0;

base_path = "./socofing/SOCOFing/Altered/Altered-Easy/";

for i=1:(n_person - 5)
    
    for l=1:10
        AIfing_test = double(imread(base_path + i + "_" + l + "_Obl.BMP"));

        %AIris_test = (AIris_test - mean(AIris_test(:))) / std(AIris_test(:));
        AIfing_test = AIfing_test(:) - mean_AIfing;

        % considero vettori colonna
        AIris_test_projected = U(:,1:k)' * AIfing_test;
        
        % Confronto tramite norma euclidea con tutte le colonne della matrice
        distances = [];
    
        for j=1: size(AIfing_matrix, 2)
            stored_AIfing = U(:,1:k)' * AIfing_matrix(:,j);
        
            distances = [distances norm(AIris_test_projected - stored_AIfing)];
        end

        percentage_distances = (1 - distances / max(distances)) * 100;
        [value, indices] = max(percentage_distances);
        
        % Calcolo l'indice della persona
        personIndex = ceil(indices/10);
        finger = mod(indices, 10);
    
        if i == personIndex && finger == l
            TP = TP + 1;
        else
            FP = FP + 1;
            
        end
        fprintf("Persona %d impronta %d\n", i, l)
    end

end

precision = uint8((TP/(TP+FP)) * 100);

fprintf("Precisione: %d%%\n", precision)
time = toc;

%%
% Easy
% soglie=[0.99 0.95 0.9 0.85 0.8 0.75 0.7 0.65 0.6 0.55 0.5 0.45 0.4 0.35 0.3 0.25 0.2 0.15 0.1];
% tempo=[647.15 523.05 467.97 410.43 355.61 312.99 288.58 228.97 179.69 156.14 133.93 105.02 84.57 53.32 25.48 9.40 6.14 3.63 2.89];
% precisione=[0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.89 0.89 0.84 0.72 0.41 0.04];

% Hard
soglie=[0.99 0.95 0.90 0.85 0.80 0.75 0.70 0.65 0.60 0.55 0.50 0.45 0.40 0.35 0.30 0.25 0.20 0.15 0.10];
tempo=[627.85 485.25 423.67 401.39 367.13 349.49 306.77 249.76 197.49 191.84 135.64 137.34 87.43 64.10 22.47 7.32 4.32 4.23 2.89];
precisione=[0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.89 0.89 0.88 0.86 0.83 0.75 0.56 0.34 0.17 0.01];

figure;
hold on;

% Asse sinistro: Tempo di esecuzione
yyaxis left;
plot(soglie, tempo, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', 'b');
ylabel('Tempo di esecuzione (s)');
xlabel('Percentuale di Energia Spiegata');

% Asse destro: Precisione
yyaxis right;
plot(soglie, precisione, '-s', 'LineWidth', 2, 'MarkerSize', 8, 'Color', 'r');
ylabel('Precisione');

% Inversione dell'asse X per partire da 1 e andare a 0
set(gca, 'XDir', 'reverse');

% Titolo e legenda
title('Variazione di Tempo e Precisione');
legend({'Tempo di esecuzione', 'Precisione'}, 'Location', 'southwest');

grid on;
hold off;

%% proietto la matrice delle impronte nello spazio ridotto
AIfing_new=[];
for i=1: size(AIfing_matrix, 2)
    AIfing_new = [AIfing_new (U(:,1:k)' * AIfing_matrix(:,i))];
end

corr_matrix = corr(AIfing_new);
figure;
imagesc(corr_matrix);
colorbar;
title('Matrice di correlazione delle impronte');
colormap jet;
%% Prendo un immagine dal set di test confrontando con singolo campione
%{
base_path = "./socofing/SOCOFing/Real/50_1.BMP";

AIfing_test = double(rgb2gray(imread(base_path)));

AIfing_test = AIfing_test(:) - mean_AIfing;

% considero vettori colonna
AIfing_test_projected = U(:,1:k)' * AIfing_test;

% Confronto tramite norma euclidea con tutte le colonne della matrice
distances = [];

for i=1 : size(AIfing_matrix, 2)
    stored_AIris = U(:,1:k)' * AIfing_matrix(:,i);

    distances = [distances norm(AIfing_test_projected - stored_AIfing)];
    %fprintf("Elaboro "+i+"\n")
end

percentage_distances = (1 - distances / max(distances)) * 100;
[value, indices] = max(percentage_distances);

fprintf("l'Impronta più simile a quella di test è %d al %d%%\n", indices, uint8(value))

plot(percentage_distances)
%}
%% confronto con persone mai inserite nella matrice

AIfing_test_matrix = [];
for i=46:50
    test_path = "./socofing/SOCOFing/Real/"+i + "_1.BMP";

    AIfing_test = imread(test_path);

    AIfing_test = double(rgb2gray(AIfing_test));

    AIfing_test = AIfing_test(:) - mean_AIfing;
    AIfing_test = U(:,1:k)' * AIfing_test;
    
    AIfing_test_matrix = [AIfing_test_matrix AIfing_test];
    
end

corr_matrix = corr(AIfing_new,AIfing_test_matrix);
figure;
imagesc(corr_matrix);
colorbar;
title('Matrice di correlazione degli iridi');
colormap jet;