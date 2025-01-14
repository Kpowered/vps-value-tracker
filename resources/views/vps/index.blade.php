@extends('layouts.app')

@section('content')
<div class="bg-white rounded-lg shadow p-6">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">VPS List</h1>
        @auth
            <a href="{{ route('vps.create') }}" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
                Add New VPS
            </a>
        @endauth
    </div>

    @if(session('success'))
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            {{ session('success') }}
        </div>
    @endif

    <div class="overflow-x-auto">
        <table class="min-w-full table-auto">
            <thead>
                <tr class="bg-gray-100">
                    <th class="px-4 py-2">Vendor</th>
                    <th class="px-4 py-2">CPU</th>
                    <th class="px-4 py-2">Memory</th>
                    <th class="px-4 py-2">Storage</th>
                    <th class="px-4 py-2">Bandwidth</th>
                    <th class="px-4 py-2">Price</th>
                    <th class="px-4 py-2">Remaining Value</th>
                    <th class="px-4 py-2">Expires</th>
                    @auth
                        <th class="px-4 py-2">Actions</th>
                    @endauth
                </tr>
            </thead>
            <tbody>
                @foreach($vpsList as $vps)
                <tr class="border-b hover:bg-gray-50">
                    <td class="px-4 py-2">{{ $vps->vendor_name }}</td>
                    <td class="px-4 py-2">{{ $vps->cpu_model }} ({{ $vps->cpu_cores }} cores)</td>
                    <td class="px-4 py-2">{{ $vps->memory_gb }} GB</td>
                    <td class="px-4 py-2">{{ $vps->storage_gb }} GB</td>
                    <td class="px-4 py-2">{{ $vps->bandwidth_gb }} GB</td>
                    <td class="px-4 py-2">
                        {{ number_format($vps->price, 2) }} {{ $vps->currency }}
                    </td>
                    <td class="px-4 py-2">
                        {{ number_format($vps->remaining_value, 2) }} {{ $vps->currency }}
                        <br>
                        <span class="text-sm text-gray-600">
                            ≈ ¥{{ number_format($vps->remaining_value_cny, 2) }}
                        </span>
                    </td>
                    <td class="px-4 py-2">{{ $vps->end_date->format('Y-m-d') }}</td>
                    @auth
                        <td class="px-4 py-2">
                            <form action="{{ route('vps.destroy', $vps) }}" method="POST" class="inline">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="text-red-600 hover:text-red-800"
                                        onclick="return confirm('Are you sure you want to delete this VPS?')">
                                    Delete
                                </button>
                            </form>
                        </td>
                    @endauth
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>
@endsection 