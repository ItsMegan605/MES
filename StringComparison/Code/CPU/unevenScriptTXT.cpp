#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <random>
#include <algorithm> 

using namespace std;

/**
 * Script to generate a large text file with a target word ("uneven")
 * distributed only within specific intervals (shuffled chunks).
 */
int main() {
    // Exact size definition: 4 GB
    const long long TARGET_SIZE = 8000LL * 1024 * 1024;
    const string filename = "giant_file.txt";

    // Buffer size: 500 MB
    const int BUFFER_SIZE = 500 * 1024 * 1024;

    // --- IRREGULAR DISTRIBUTION PARAMETERS ---
    const int N = 12;            // Total number of intervals/chunks
    const int M = 4;             // Number of intervals that WILL contain the target word
    const string TARGET_WORD = "unevenstring";

    // 1. Dictionary WITHOUT the target word
    vector<string> words_no_target = {
        "before", "been", "only",
        "two", "where", "time", "life", "year", "man", "day", "little", "home",
        "work", "always", "sun", "moon", "sea", "mountain",  "tree",
        "water", "earth", "cat", "dog", "car", "road", "star",
        "house", "job", "always", "sun", "moon", "ocean", "peak", "flame",
        "liquid", "ground", "kitten", "puppy", "vehicle", "fork", "trees", "wood", "dawn",
        "hotel", "sapling", "branch", "abracadabra", "strawberry", "opportunity", "environment",
        "conversation", "miscellaneous", "unpredictable", "congratulations" , "characteristics",
        "absolutely", "acceptable", "background", "collection", "completely", "department", "experience", "foundation", 
        "generation", "importance", "literature", "management", "particular", "philosophy", "technology", "understand", "vocabulary", 
        "achievement", "appropriate", "comfortable", "competitive", "description", "educational", "fundamental", "imagination", "independent", "information", 
        "measurement", "performance", "perspective", "significant", "temperature", "agricultural", "championship", "construction", "contribution", 
        "intelligence", "introduction", "manufacturer", 
        "organization", "presentation", "relationship", "satisfaction", "successfully", "transmission", "accommodation", 
        "administrator", "communication", "comprehensive", "consideration", "environmental", "international", "investigation",
        "manufacturing", "understanding", "administration", "discrimination", "identification", "implementation", "infrastructure", 
        "representative", "transportation", "acknowledgement", "instrumentation", "interchangeable", "procrastination", "recommendations", 
        "standardization"
    };

    // 2. Dictionary WITH the target word
    vector<string> words_all = words_no_target;
    words_all.push_back(TARGET_WORD);
    words_all.push_back(TARGET_WORD);

    random_device rd;
    mt19937 rng(rd());
    uniform_int_distribution<int> dist_no(0, words_no_target.size() - 1);
    uniform_int_distribution<int> dist_all(0, words_all.size() - 1);
    uniform_int_distribution<int> dist_newline(0, 14);

    long long INTERVAL_SIZE = TARGET_SIZE / N;
    vector<bool> valid_intervals(N, false);

    // Mark M intervals as "valid" to contain the target word
    for (int i = 0; i < M && i < N; ++i) {
        valid_intervals[i] = true;
    }

    // Randomize which intervals will contain the word
    shuffle(valid_intervals.begin(), valid_intervals.end(), rng);

    cout << "Starting generation of " << TARGET_SIZE / (1024 * 1024) << " MB split into " << N << " intervals." << endl;
    cout << "The word '" << TARGET_WORD << "' will appear ONLY in the following intervals: ";
    for (int i = 0; i < N; ++i) {
        if (valid_intervals[i]) cout << i + 1 << " ";
    }
    cout << "\n\nThis might take a few minutes..." << endl;

    ofstream outFile(filename, ios::binary);
    if (!outFile) {
        cerr << "Critical Error: Could not create or open the file!" << endl;
        return 1;
    }

    long long bytesWritten = 0;
    string buffer;
    buffer.reserve(BUFFER_SIZE + 100);

    while (bytesWritten < TARGET_SIZE) {
        buffer.clear();

        while (buffer.size() < BUFFER_SIZE && (bytesWritten + buffer.size()) < TARGET_SIZE) {

            long long current_pos = bytesWritten + buffer.size();
            int current_interval = current_pos / INTERVAL_SIZE;
            if (current_interval >= N) current_interval = N - 1;

            string next_word;

            if (valid_intervals[current_interval]) {
                next_word = words_all[dist_all(rng)];

                // --- BOUNDARY PROTECTION BLOCK ---
                // If we picked the target word, we must ensure it (plus space)
                // doesn't physically cross into a forbidden interval.
                if (next_word == TARGET_WORD) {
                    long long end_pos = current_pos + next_word.length() + 1;
                    int next_interval = end_pos / INTERVAL_SIZE;

                    // If the word would overflow into a forbidden interval, replace it
                    if (next_interval < N && !valid_intervals[next_interval]) {
                        next_word = words_no_target[dist_no(rng)];
                    }
                }
            } else {
                next_word = words_no_target[dist_no(rng)];
            }

            buffer += next_word + " ";

            if (dist_newline(rng) == 0) {
                buffer += "\n";
            }
        }

        // --- EXACT TRUNCATION ---
        // If the buffer exceeds the exact target size, resize it.
        // This ensures the byte alignment matches perfectly during reading/chunking.
        if (bytesWritten + buffer.size() > TARGET_SIZE) {
            buffer.resize(TARGET_SIZE - bytesWritten);
        }

        outFile.write(buffer.c_str(), buffer.size());
        bytesWritten += buffer.size();

        if (bytesWritten % (500LL * 1024 * 1024) < buffer.size()) {
            cout << "Progress: " << bytesWritten / (1024 * 1024) << " MB written out of " << TARGET_SIZE / (1024 * 1024) << " MB..." << endl;
        }
    }

    outFile.close();
    cout << "\nOperation completed successfully!" << endl;
    
    return 0;
}