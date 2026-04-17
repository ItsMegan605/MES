#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <random>

using namespace std;

// Script to generate a massive text file for testing purposes
int main() {
    // Target size definition: ~4 GB (4000 MB)
    const long long TARGET_SIZE = 4000LL * 1024 * 1024;
    const string filename = "giant_file.txt";

    // Buffer size: 500 MB (writing in large blocks is much faster)
    const int BUFFER_SIZE = 500 * 1024 * 1024;

    // Dictionary of words to populate the file
    vector<string> words = {
        "what", "when", "much", "before", "we", "be", "been", "only",
        "two", "where", "time", "life", "year", "man", "day", "little", "home",
        "work", "always", "sun", "moon", "sea", "mountain", "fire", "tree",
        "water", "earth", "cat", "dog", "car", "road", "sky", "star", "house",
        "job", "always", "sun", "moon", "ocean", "peak", "flame",
        "liquid", "ground", "kitten", "puppy", "vehicle", "fork", "trees", "wood", "dawn",
        "hotel", "sapling", "branch", "treat"
    };

    // Open file in binary mode to maximize write speed
    ofstream outFile(filename, ios::binary);
    if (!outFile) {
        cerr << "Critical Error: Could not create or open the file!" << endl;
        return 1;
    }

    // Set up a random number generator (faster and more reliable than rand())
    random_device rd;
    mt19937 rng(rd());
    uniform_int_distribution<int> dist(0, words.size() - 1);

    long long bytesWritten = 0;
    string buffer;

    // Pre-reserve memory for the buffer to avoid slow reallocations
    buffer.reserve(BUFFER_SIZE + 100);

    cout << "Starting file generation (" << TARGET_SIZE / (1024 * 1024) << " MB). This might take a few minutes..." << endl;

    while (bytesWritten < TARGET_SIZE) {
        buffer.clear();

        // Fill the buffer until it reaches the BUFFER_SIZE
        while (buffer.size() < BUFFER_SIZE) {
            buffer += words[dist(rng)] + " ";

            // Occasionally insert a newline instead of a space for better formatting
            if (dist(rng) % 15 == 0) {
                buffer += "\n";
            }
        }

        // Write the entire block to disk
        outFile.write(buffer.c_str(), buffer.size());
        bytesWritten += buffer.size();

        // Print progress update every 500 MB written
        if (bytesWritten % (500LL * 1024 * 1024) < buffer.size()) {
            cout << "Progress: " << bytesWritten / (1024 * 1024) << " MB written out of " << TARGET_SIZE / (1024 * 1024) << " MB..." << endl;
        }
    }

    outFile.close();
    cout << "\nOperation completed successfully! The file '" << filename << "' is ready." << endl;
    
    return 0;
}