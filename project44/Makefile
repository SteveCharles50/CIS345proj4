NVCC = nvcc
TARGET = run
FILE = p4_template.cu

$(TARGET): $(FILE)
	$(NVCC) -o $(TARGET) $(FILE)
	./$(TARGET)

# Clean up
clean:
	rm -f $(TARGET)
