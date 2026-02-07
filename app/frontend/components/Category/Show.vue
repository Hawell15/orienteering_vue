<template>
    <div class="mt-4 p-5 bg-light text-black rounded --bs-gray-500">
        <h1> {{category.full_name}}</h1>
        <p><strong>Denumirea: </strong>{{category.category_name}}</p>
        <hr class="my-4">
        <p><strong>Puncte: </strong>{{category.points}}</p>
        <p><strong>Validitate: </strong>{{category.validaty_period}} ani</p>
        <p><strong>Numarul de sportivi: </strong><a :href="`/runners?category=${category.id}`">{{runners.length}}</a></p>
        <p><strong>Numarul de rezultate: </strong><a :href="`/results?category=${category.id}`">{{results.length}}</a></p>
    </div>
    <p class="d-inline-flex gap-1">
        <a class="btn btn-primary" data-bs-toggle="collapse" href="#runnersTable" role="button" aria-expanded="false" aria-controls="runnersTable">
            Sportivi
        </a>
    </p>
    <div class="collapse" id="runnersTable">
        <div class="card card-body">
            <RunnersTable :elements="runners" @order="orderRunnerTable"></RunnersTable>
        </div>
    </div>
    <br>
    <p class="d-inline-flex gap-1">
        <a class="btn btn-primary" data-bs-toggle="collapse" href="#resultsTable" role="button" aria-expanded="false" aria-controls="resultsTable">
            Rezultate
        </a>
    </p>
    <div class="collapse" id="resultsTable">
        <div class="card card-body">
            <ResultsTable :elements="results" @order="orderResultTable"></ResultsTable>
        </div>
    </div>
    <p class="lead">
        <button class="btn btn-sm btn-success" @click="editElement(category)">Editeaza</button>
        <button class="btn btn-danger btn-sm" @click="deleteCategory(category.id)">Sterge</button>
        <button class="btn btn-secondary btn-sm" @click="goBack()">Înapoi</button>
    </p>
    <Modal ref="modal" :category="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'
import RunnersTable from '../Runner/Table.vue'
import ResultsTable from '../Result/Table.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[  name="csrf-token"]').getAttribute('content')


const category = ref({})
const modalElement = ref({})
const modal = ref(null)
const runners = ref([])
const results = ref([])
const categoryId = ref("")
const runnerSorting = ref({
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc"
})

const resultSorting = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc"
})

onMounted(() => {
    categoryId.value = window.location.pathname.split('/').pop();
    getData();
    getRunners();
    getResults();
})

async function getData() {
    const res = await axios.get(`/categories/${categoryId.value}.json`)
    category.value = res.data;
}

async function getRunners() {
    runnerSorting.value["category"] = categoryId.value
    const res = await axios.get('/runners.json', { params: runnerSorting.value })
    runners.value = res.data;
}

async function getResults() {
    resultSorting.value["category"] = categoryId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
}

function orderRunnerTable(sortKey) {
    orderTable(sortKey, runnerSorting)
    getRunners()
}

function orderResultTable(sortKey) {
    orderTable(sortKey, resultSorting)
    getResults()
}

function orderTable(sortKey, filters) {
    const isCurrentSort = filters.value["sorting[sort_by]"] === sortKey;
    const currentDir = filters.value["sorting[direction]"];

    filters.value["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters.value["sorting[sort_by]"] = sortKey;
}

function editElement(category) {
    modalElement.value = { ...category }
    modal.value.show()
}

function updateElement(categoryData, done) {
    axios.patch(`/categories/${categoryData.id}.json`, { category: categoryData }).then(res => {
        category.value = res.data
        done()
    })
}

function deleteCategory(id) {
    if (confirm('Esti sigur ca vrei sa stergi această categorie?')) {
        axios.delete(`/categories/${id}`).then(() => {
            if (document.referrer) {
                window.location = document.referrer;
            } else {
                window.location = "/categories";
            }
        })
    }
}

function goBack() {
    if (document.referrer) {
        window.location = document.referrer;
    } else {
        window.location = "/categories";
    }
}
</script>
