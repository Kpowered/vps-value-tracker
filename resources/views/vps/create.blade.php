@extends('layouts.app')

@section('content')
<div class="bg-white rounded-lg shadow p-6 max-w-2xl mx-auto">
    <h1 class="text-2xl font-bold mb-6">Add New VPS</h1>

    <form action="{{ route('vps.store') }}" method="POST">
        @csrf
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="mb-4">
                <label class="block text-gray-700 mb-2">Vendor Name</label>
                <input type="text" name="vendor_name" class="form-input w-full rounded" required>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 mb-2">CPU Model</label>
                <input type="text" name="cpu_model" class="form-input w-full rounded" required>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 mb-2">CPU Cores</label>
                <select name="cpu_cores" class="form-select w-full rounded" required>
                    @foreach(range(1, 32) as $cores)
                        <option value="{{ $cores }}">{{ $cores }}</option>
                    @endforeach
                </select>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 mb-2">Memory (GB)</label>
                <select name="memory_gb" class="form-select w-full rounded" required>
                    @foreach([1, 2, 4, 8, 16, 32, 64, 128] as $memory)
                        <option value="{{ $memory }}">{{ $memory }} GB</option>
                    @endforeach
                </select>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 mb-2">Storage (GB)</label>
                <input type="number" name="storage_gb" class="form-input w-full rounded" required>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 mb-2">Bandwidth (GB)</label>
                <input type="number" name="bandwidth_gb" class="form-input w-full rounded" required>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 mb-2">Price</label>
                <input type="number" step="0.01" name="price" class="form-input w-full rounded" required>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 mb-2">Currency</label>
                <select name="currency" class="form-select w-full rounded" required>
                    <option value="CNY">CNY - Chinese Yuan</option>
                    <option value="USD">USD - US Dollar</option>
                    <option value="EUR">EUR - Euro</option>
                    <option value="GBP">GBP - British Pound</option>
                    <option value="CAD">CAD - Canadian Dollar</option>
                    <option value="JPY">JPY - Japanese Yen</option>
                </select>
            </div>
        </div>

        <div class="mt-6">
            <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
                Add VPS
            </button>
        </div>
    </form>
</div>
@endsection 